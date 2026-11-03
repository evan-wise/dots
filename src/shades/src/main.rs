//! shades: render a Shadertoy-style fragment shader as the wallpaper on every
//! output, using wlr-layer-shell (Hyprland, sway, ...) and OpenGL ES 3.
//!
//! Several shaders can be given; with `--cycle` they crossfade into one another
//! by drawing the incoming shader over the current one with alpha blending.
//! A shared Gruvbox palette and noise library (`common.glsl`) is prepended to
//! every shader. Each shader file defines `void mainImage(out vec4 fragColor, in vec2 fragCoord)`
//! and may use the uniforms `iResolution` (vec3) and `iTime` (float).
//!
//! Power management is built in (see `power.rs`): full frame rate (--fps) on
//! AC, and on battery either pause (the last frame stays on screen) or throttle
//! to --low-fps, per --battery. It also pauses while hyprlock is running.
//!
//! Surfaces are rendered at the output's logical resolution and upscaled by
//! the compositor, which is plenty for a wallpaper and keeps GPU cost low.

mod power;

use std::error::Error;
use std::ffi::c_void;
use std::os::fd::AsFd;
use std::time::{Duration, Instant};

use glow::HasContext;
use khronos_egl as egl;
use nix::poll::{poll, PollFd, PollFlags, PollTimeout};
use nix::sys::signal::{SigSet, Signal};
use nix::sys::signalfd::{SfdFlags, SignalFd};
use wayland_client::globals::{registry_queue_init, GlobalListContents};
use wayland_client::protocol::{
    wl_compositor::WlCompositor, wl_output::WlOutput, wl_region::WlRegion, wl_registry,
    wl_registry::WlRegistry, wl_surface::WlSurface,
};
use wayland_client::{Connection, Dispatch, Proxy, QueueHandle};
use wayland_egl::WlEglSurface;
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{Layer, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, Anchor, ZwlrLayerSurfaceV1},
};

type Result<T> = std::result::Result<T, Box<dyn Error>>;

#[derive(Clone, Copy, PartialEq, Eq)]
enum Mode {
    Run,
    Throttle,
    Pause,
}

struct Args {
    shaders: Vec<String>,
    fps: f64,
    low_fps: f64,
    /// What to do on battery power.
    battery: Mode,
    /// Seconds between the start of one crossfade and the next; 0 disables cycling.
    cycle: f64,
    fade: f64,
    shuffle: bool,
}

const USAGE: &str = "usage: shades (--shader FILE)... | --shader-dir DIR  [options]
  -s, --shader FILE     fragment shader (Shadertoy mainImage style); repeatable
  -d, --shader-dir DIR  use every *.frag in DIR
  -c, --cycle SECS      crossfade to the next shader every SECS (default 0: off)
      --fade SECS       crossfade duration (default 4)
      --shuffle         pick the next shader at random instead of in order
  -f, --fps N           frame rate while running (default 60)
  -b, --battery MODE    on battery: pause, throttle or run (default throttle)
  -l, --low-fps N       frame rate when throttled on battery (default 20)
Always pauses while hyprlock is running.";

fn parse_args() -> std::result::Result<Args, String> {
    let mut a = Args {
        shaders: Vec::new(),
        fps: 60.0,
        low_fps: 20.0,
        battery: Mode::Throttle,
        cycle: 0.0,
        fade: 4.0,
        shuffle: false,
    };
    let mut it = std::env::args().skip(1);
    while let Some(flag) = it.next() {
        let mut value = || it.next().ok_or(format!("{flag} needs a value"));
        match flag.as_str() {
            "-s" | "--shader" => a.shaders.push(value()?),
            "-d" | "--shader-dir" => {
                let dir = value()?;
                let mut found: Vec<String> = std::fs::read_dir(&dir)
                    .map_err(|e| format!("cannot read {dir}: {e}"))?
                    .filter_map(|e| e.ok())
                    .map(|e| e.path())
                    .filter(|p| p.extension().is_some_and(|x| x == "frag"))
                    .map(|p| p.to_string_lossy().into_owned())
                    .collect();
                found.sort();
                a.shaders.extend(found);
            }
            "-c" | "--cycle" => a.cycle = value()?.parse().map_err(|_| "bad --cycle")?,
            "--fade" => a.fade = value()?.parse().map_err(|_| "bad --fade")?,
            "--shuffle" => a.shuffle = true,
            "-f" | "--fps" => a.fps = value()?.parse().map_err(|_| "bad --fps")?,
            "-l" | "--low-fps" => a.low_fps = value()?.parse().map_err(|_| "bad --low-fps")?,
            "-b" | "--battery" => {
                a.battery = match value()?.as_str() {
                    "run" => Mode::Run,
                    "throttle" => Mode::Throttle,
                    "pause" => Mode::Pause,
                    other => return Err(format!("unknown battery mode {other}")),
                }
            }
            "-h" | "--help" => return Err(String::new()),
            other => return Err(format!("unknown argument {other}")),
        }
    }
    if a.shaders.is_empty() {
        return Err("no shaders given".into());
    }
    if a.fps <= 0.0 || a.low_fps <= 0.0 || a.fade <= 0.0 || a.cycle < 0.0 {
        return Err("frame rates and --fade must be positive".into());
    }
    Ok(a)
}

/// Which shaders to draw this frame, and how far each one has progressed.
struct Scene {
    current: (usize, f32),
    /// (shader, its time, blend alpha) while crossfading into the next shader.
    incoming: Option<(usize, f32, f32)>,
}

/// Decides when to crossfade between shaders. Driven by shader time, so
/// pausing or throttling never skips ahead.
struct Cycle {
    count: usize,
    interval: f64,
    fade: f64,
    shuffle: bool,
    rng: u64,
    current: usize,
    current_start: f64,
    next: usize,
}

impl Cycle {
    fn new(count: usize, cycle: f64, fade: f64, shuffle: bool) -> Self {
        let seed = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_or(1, |d| d.as_nanos() as u64)
            | 1;
        let mut c = Cycle {
            count,
            // Each shader must be fully visible for at least as long as it fades.
            interval: if cycle > 0.0 { cycle.max(fade * 2.0) } else { 0.0 },
            fade,
            shuffle,
            rng: seed,
            current: 0,
            current_start: 0.0,
            next: 0,
        };
        if shuffle && count > 1 {
            c.current = c.random() % count;
        }
        c.next = c.pick();
        c
    }

    fn random(&mut self) -> usize {
        // xorshift64
        self.rng ^= self.rng << 13;
        self.rng ^= self.rng >> 7;
        self.rng ^= self.rng << 17;
        (self.rng >> 11) as usize
    }

    fn pick(&mut self) -> usize {
        if self.count < 2 {
            0
        } else if self.shuffle {
            loop {
                let r = self.random() % self.count;
                if r != self.current {
                    return r;
                }
            }
        } else {
            (self.current + 1) % self.count
        }
    }

    fn scene(&mut self, t: f64) -> Scene {
        if self.interval > 0.0 && self.count > 1 {
            loop {
                let fade_start = self.current_start + self.interval;
                if t < fade_start + self.fade {
                    break;
                }
                self.current = self.next;
                self.current_start = fade_start;
                self.next = self.pick();
            }
        }
        let current = (self.current, (t - self.current_start) as f32);
        let fade_start = self.current_start + self.interval;
        let incoming = (self.interval > 0.0 && self.count > 1 && t >= fade_start).then(|| {
            let x = ((t - fade_start) / self.fade).clamp(0.0, 1.0);
            (self.next, (t - fade_start) as f32, (x * x * (3.0 - 2.0 * x)) as f32)
        });
        Scene { current, incoming }
    }
}

// ---------------------------------------------------------------------------
// EGL / GL
// ---------------------------------------------------------------------------

const VERTEX_SRC: &str = "#version 300 es
void main() {
    // Fullscreen triangle generated from the vertex index; no buffers needed.
    vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}
";

const FRAG_PREFIX: &str = "#version 300 es
precision highp float;
uniform vec3 iResolution;
uniform float iTime;
uniform float iFade;  // output alpha; < 1 while crossfading in
out vec4 shades_out;
";

/// Shared Gruvbox palette and noise helpers, prepended to every shader.
const COMMON_SRC: &str = include_str!("common.glsl");
const LINE_RESET: &str = "\n#line 1\n";

const FRAG_SUFFIX: &str = "
void main() {
    vec4 c = vec4(0.0, 0.0, 0.0, 1.0);
    mainImage(c, gl_FragCoord.xy);
    shades_out = vec4(c.rgb, iFade);
}
";

const EGL_OPENGL_ES3_BIT: egl::Int = 0x0040;

struct Program {
    program: glow::Program,
    u_resolution: Option<glow::UniformLocation>,
    u_time: Option<glow::UniformLocation>,
    u_fade: Option<glow::UniformLocation>,
}

struct Gfx {
    egl: egl::DynamicInstance<egl::EGL1_4>,
    display: egl::Display,
    config: egl::Config,
    context: egl::Context,
    /// (name, source) of every shader, in cycle order.
    sources: Vec<(String, String)>,
    // Created lazily: GL needs a current surface before it can be used.
    gl: Option<glow::Context>,
    vao: Option<glow::VertexArray>,
    /// One slot per source; None if that shader failed to compile.
    programs: Vec<Option<Program>>,
}

impl Gfx {
    fn new(conn: &Connection, shader_paths: &[String]) -> Result<Self> {
        let mut sources = Vec::new();
        for path in shader_paths {
            let src = std::fs::read_to_string(path).map_err(|e| format!("cannot read {path}: {e}"))?;
            sources.push((path.clone(), src));
        }
        let egl = unsafe { egl::DynamicInstance::<egl::EGL1_4>::load_required() }
            .map_err(|e| format!("cannot load libEGL: {e}"))?;
        let display_ptr = conn.backend().display_ptr() as *mut c_void;
        let display = unsafe { egl.get_display(display_ptr) }.ok_or("eglGetDisplay failed")?;
        egl.initialize(display)?;
        egl.bind_api(egl::OPENGL_ES_API)?;
        let config = egl
            .choose_first_config(
                display,
                &[
                    egl::SURFACE_TYPE, egl::WINDOW_BIT,
                    egl::RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
                    egl::RED_SIZE, 8, egl::GREEN_SIZE, 8, egl::BLUE_SIZE, 8,
                    egl::NONE,
                ],
            )?
            .ok_or("no suitable EGL config")?;
        let context = egl.create_context(
            display,
            config,
            None,
            &[egl::CONTEXT_CLIENT_VERSION, 3, egl::NONE],
        )?;
        Ok(Gfx { egl, display, config, context, sources, gl: None, vao: None, programs: Vec::new() })
    }

    fn make_current(&self, surface: egl::Surface) -> Result<()> {
        self.egl
            .make_current(self.display, Some(surface), Some(surface), Some(self.context))?;
        // We pace frames ourselves; don't let swap block on the compositor.
        self.egl.swap_interval(self.display, 0)?;
        Ok(())
    }

    /// Compiles every shader. A shader that fails is reported and drawn as a
    /// plain background; it is an error only if none of them compile.
    fn init_programs(&mut self) -> Result<()> {
        let egl = &self.egl;
        let gl = unsafe {
            glow::Context::from_loader_function(|name| {
                egl.get_proc_address(name).map_or(std::ptr::null(), |p| p as *const c_void)
            })
        };
        let vao = unsafe { gl.create_vertex_array()? };
        let mut programs = Vec::new();
        for (name, src) in &self.sources {
            match unsafe { build_program(&gl, src) } {
                Ok(p) => programs.push(Some(p)),
                Err(e) => {
                    eprintln!("shades: {name}: {e}");
                    programs.push(None);
                }
            }
        }
        if programs.iter().all(Option::is_none) {
            return Err("no shader compiled".into());
        }
        self.gl = Some(gl);
        self.vao = Some(vao);
        self.programs = programs;
        Ok(())
    }

    fn draw(&mut self, out: &Output, scene: &Scene) -> Result<()> {
        let Some(surface) = out.egl_surface else { return Ok(()) };
        self.make_current(surface)?;
        if self.gl.is_none() {
            self.init_programs()?;
        }
        let gl = self.gl.as_ref().unwrap();
        let (w, h) = out.size;
        unsafe {
            gl.viewport(0, 0, w, h);
            gl.bind_vertex_array(self.vao);
            gl.disable(glow::BLEND);
            // A shader that failed to compile leaves the screen cleared to Gruvbox bg0.
            gl.clear_color(0.157, 0.157, 0.157, 1.0);
            gl.clear(glow::COLOR_BUFFER_BIT);
            let pass = |idx: usize, time: f32, fade: f32| {
                if let Some(Some(p)) = self.programs.get(idx) {
                    gl.use_program(Some(p.program));
                    gl.uniform_3_f32(p.u_resolution.as_ref(), w as f32, h as f32, 1.0);
                    gl.uniform_1_f32(p.u_time.as_ref(), time);
                    gl.uniform_1_f32(p.u_fade.as_ref(), fade);
                    gl.draw_arrays(glow::TRIANGLES, 0, 3);
                }
            };
            pass(scene.current.0, scene.current.1, 1.0);
            if let Some((idx, time, alpha)) = scene.incoming {
                // Blend the incoming shader over the current one; no FBOs needed.
                gl.enable(glow::BLEND);
                gl.blend_func(glow::SRC_ALPHA, glow::ONE_MINUS_SRC_ALPHA);
                pass(idx, time, alpha);
            }
        }
        self.egl.swap_buffers(self.display, surface)?;
        Ok(())
    }
}

unsafe fn build_program(gl: &glow::Context, shader_src: &str) -> Result<Program> {
    let compile = |kind, sources: &[&str], label: &str| -> Result<glow::Shader> {
        let shader = gl.create_shader(kind)?;
        gl.shader_source(shader, &sources.concat());
        gl.compile_shader(shader);
        if !gl.get_shader_compile_status(shader) {
            return Err(format!("{label} failed to compile:\n{}", gl.get_shader_info_log(shader)).into());
        }
        Ok(shader)
    };
    let vs = compile(glow::VERTEX_SHADER, &[VERTEX_SRC], "vertex shader")?;
    let fs = compile(
        glow::FRAGMENT_SHADER,
        &[FRAG_PREFIX, COMMON_SRC, LINE_RESET, shader_src, FRAG_SUFFIX],
        "fragment shader",
    )?;
    let program = gl.create_program()?;
    gl.attach_shader(program, vs);
    gl.attach_shader(program, fs);
    gl.link_program(program);
    if !gl.get_program_link_status(program) {
        return Err(format!("link failed:\n{}", gl.get_program_info_log(program)).into());
    }
    gl.delete_shader(vs);
    gl.delete_shader(fs);
    Ok(Program {
        program,
        u_resolution: gl.get_uniform_location(program, "iResolution"),
        u_time: gl.get_uniform_location(program, "iTime"),
        u_fade: gl.get_uniform_location(program, "iFade"),
    })
}

// ---------------------------------------------------------------------------
// Wayland
// ---------------------------------------------------------------------------

struct Output {
    /// wl_registry global name; identifies the output across hotplug events.
    name: u32,
    wl_output: WlOutput,
    surface: WlSurface,
    layer: ZwlrLayerSurfaceV1,
    egl_window: Option<WlEglSurface>,
    egl_surface: Option<egl::Surface>,
    size: (i32, i32),
}

struct App {
    compositor: WlCompositor,
    layer_shell: ZwlrLayerShellV1,
    outputs: Vec<Output>,
    gfx: Gfx,
    shader_time: f64,
    cycle: Cycle,
    error: Option<Box<dyn Error>>,
}

impl App {
    fn add_output(&mut self, registry: &WlRegistry, name: u32, version: u32, qh: &QueueHandle<App>) {
        let wl_output: WlOutput = registry.bind(name, version.min(3), qh, ());
        let surface = self.compositor.create_surface(qh, ());
        let layer = self.layer_shell.get_layer_surface(
            &surface,
            Some(&wl_output),
            Layer::Background,
            "shades".into(),
            qh,
            name,
        );
        layer.set_size(0, 0);
        layer.set_anchor(Anchor::Top | Anchor::Bottom | Anchor::Left | Anchor::Right);
        layer.set_exclusive_zone(-1);
        // Empty input region so the wallpaper never intercepts pointer events.
        let empty = self.compositor.create_region(qh, ());
        surface.set_input_region(Some(&empty));
        empty.destroy();
        surface.commit();
        self.outputs.push(Output {
            name,
            wl_output,
            surface,
            layer,
            egl_window: None,
            egl_surface: None,
            size: (0, 0),
        });
    }

    fn remove_output(&mut self, name: u32) {
        let Some(i) = self.outputs.iter().position(|o| o.name == name) else { return };
        let out = self.outputs.remove(i);
        if let Some(s) = out.egl_surface {
            let _ = self.gfx.egl.destroy_surface(self.gfx.display, s);
        }
        drop(out.egl_window);
        out.layer.destroy();
        out.surface.destroy();
        if out.wl_output.version() >= 3 {
            out.wl_output.release();
        }
    }

    fn draw_all(&mut self) {
        let scene = self.cycle.scene(self.shader_time);
        for i in 0..self.outputs.len() {
            if let Err(e) = self.gfx.draw(&self.outputs[i], &scene) {
                self.error = Some(e);
                return;
            }
        }
    }
}

impl Dispatch<WlRegistry, GlobalListContents> for App {
    fn event(
        app: &mut Self,
        registry: &WlRegistry,
        event: wl_registry::Event,
        _: &GlobalListContents,
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        match event {
            wl_registry::Event::Global { name, interface, version } if interface == "wl_output" => {
                app.add_output(registry, name, version, qh);
            }
            wl_registry::Event::GlobalRemove { name } => app.remove_output(name),
            _ => {}
        }
    }
}

impl Dispatch<ZwlrLayerSurfaceV1, u32> for App {
    fn event(
        app: &mut Self,
        layer: &ZwlrLayerSurfaceV1,
        event: zwlr_layer_surface_v1::Event,
        name: &u32,
        _: &Connection,
        _: &QueueHandle<Self>,
    ) {
        match event {
            zwlr_layer_surface_v1::Event::Configure { serial, width, height } => {
                layer.ack_configure(serial);
                let Some(i) = app.outputs.iter().position(|o| o.name == *name) else { return };
                if width == 0 || height == 0 {
                    return;
                }
                let (w, h) = (width as i32, height as i32);
                let gfx = &app.gfx;
                let out = &mut app.outputs[i];
                out.size = (w, h);
                match &out.egl_window {
                    Some(win) => win.resize(w, h, 0, 0),
                    None => {
                        let win = match WlEglSurface::new(out.surface.id(), w, h) {
                            Ok(win) => win,
                            Err(e) => {
                                app.error = Some(e.into());
                                return;
                            }
                        };
                        let surf = unsafe {
                            gfx.egl.create_window_surface(
                                gfx.display,
                                gfx.config,
                                win.ptr() as egl::NativeWindowType,
                                None,
                            )
                        };
                        match surf {
                            Ok(s) => out.egl_surface = Some(s),
                            Err(e) => {
                                app.error = Some(e.into());
                                return;
                            }
                        }
                        out.egl_window = Some(win);
                    }
                }
                // Always render once (even while paused) so the surface is
                // mapped and shows a frame.
                let scene = app.cycle.scene(app.shader_time);
                if let Err(e) = app.gfx.draw(&app.outputs[i], &scene) {
                    app.error = Some(e);
                }
            }
            zwlr_layer_surface_v1::Event::Closed => app.remove_output(*name),
            _ => {}
        }
    }
}

// Objects whose events we don't care about.
macro_rules! ignore_events {
    ($($ty:ty),*) => {$(
        impl Dispatch<$ty, ()> for App {
            fn event(_: &mut Self, _: &$ty, _: <$ty as Proxy>::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
        }
    )*};
}
ignore_events!(WlCompositor, WlOutput, WlRegion, WlSurface, ZwlrLayerShellV1);

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------

fn run() -> Result<()> {
    let args = match parse_args() {
        Ok(a) => a,
        Err(msg) => {
            if !msg.is_empty() {
                eprintln!("shades: {msg}");
            }
            eprintln!("{USAGE}");
            std::process::exit(2);
        }
    };

    // Handle signals through a signalfd so they wake poll() without races.
    let mut mask = SigSet::empty();
    for s in [Signal::SIGTERM, Signal::SIGINT, Signal::SIGHUP] {
        mask.add(s);
    }
    mask.thread_block()?;
    let sigfd = SignalFd::with_flags(&mask, SfdFlags::SFD_CLOEXEC | SfdFlags::SFD_NONBLOCK)?;

    let conn = Connection::connect_to_env()?;
    let (globals, mut queue) = registry_queue_init::<App>(&conn)?;
    let qh = queue.handle();

    let gfx = Gfx::new(&conn, &args.shaders)?;
    let compositor: WlCompositor = globals.bind(&qh, 4..=6, ())?;
    let layer_shell: ZwlrLayerShellV1 =
        globals.bind(&qh, 1..=4, ()).map_err(|_| "compositor lacks wlr-layer-shell")?;
    let mut app = App {
        compositor,
        layer_shell,
        outputs: Vec::new(),
        gfx,
        shader_time: 0.0,
        cycle: Cycle::new(args.shaders.len(), args.cycle, args.fade, args.shuffle),
        error: None,
    };

    let initial: Vec<(u32, u32)> = globals.contents().with_list(|list| {
        list.iter().filter(|g| g.interface == "wl_output").map(|g| (g.name, g.version)).collect()
    });
    for (name, version) in initial {
        app.add_output(globals.registry(), name, version, &qh);
    }

    let watcher = power::Watcher::open();
    // Safety net in case a uevent is missed, and the only way to notice hyprlock.
    const RECHECK: Duration = Duration::from_secs(5);
    let desired_mode = || {
        if power::screen_locked() {
            Mode::Pause
        } else if power::on_ac() {
            Mode::Run
        } else {
            args.battery
        }
    };
    let mut mode = desired_mode();
    let mut next_check = Instant::now() + RECHECK;
    let mut last_draw = Instant::now();
    let mut next_draw = last_draw;
    let mut running = true;

    while running {
        queue.dispatch_pending(&mut app)?;
        if let Some(e) = app.error.take() {
            return Err(e);
        }
        queue.flush()?;
        let Some(guard) = queue.prepare_read() else { continue };

        // Wake for the next frame (unless paused) or the next periodic check.
        let mut wake = next_check;
        if mode != Mode::Pause {
            wake = wake.min(next_draw);
        }
        let ms = wake.saturating_duration_since(Instant::now()).as_secs_f64() * 1000.0;
        let timeout = PollTimeout::try_from(ms.ceil() as i32)?;
        let (wl_ready, sig_ready, power_ready) = {
            let mut fds = vec![
                PollFd::new(guard.connection_fd(), PollFlags::POLLIN),
                PollFd::new(sigfd.as_fd(), PollFlags::POLLIN),
            ];
            if let Some(fd) = watcher.fd() {
                fds.push(PollFd::new(fd, PollFlags::POLLIN));
            }
            match poll(&mut fds, timeout) {
                Ok(_) | Err(nix::errno::Errno::EINTR) => {}
                Err(e) => return Err(e.into()),
            }
            let ready = |f: Option<&PollFd>| {
                f.and_then(|f| f.revents()).is_some_and(|r| r.contains(PollFlags::POLLIN))
            };
            (ready(fds.first()), ready(fds.get(1)), ready(fds.get(2)))
        };
        if wl_ready {
            guard.read()?;
        } else {
            drop(guard);
        }
        queue.dispatch_pending(&mut app)?;

        if sig_ready {
            while sigfd.read_signal()?.is_some() {
                running = false;
            }
        }

        let power_event = power_ready && watcher.drain();
        if power_event || Instant::now() >= next_check {
            next_check = Instant::now() + RECHECK;
            let new_mode = desired_mode();
            if new_mode != mode {
                mode = new_mode;
                last_draw = Instant::now();
                next_draw = last_draw;
            }
        }

        if mode != Mode::Pause && Instant::now() >= next_draw {
            let t = Instant::now();
            // Don't let a long stall make the animation jump; time only
            // advances while we are actually rendering.
            let dt = t.duration_since(last_draw).as_secs_f64();
            if dt <= 0.5 {
                app.shader_time += dt;
            }
            last_draw = t;
            app.draw_all();
            let fps = if mode == Mode::Throttle { args.low_fps } else { args.fps };
            next_draw = Instant::now() + Duration::from_secs_f64(1.0 / fps);
        }
    }

    while let Some(name) = app.outputs.first().map(|o| o.name) {
        app.remove_output(name);
    }
    queue.flush()?;
    Ok(())
}

fn main() {
    if let Err(e) = run() {
        eprintln!("shades: {e}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn single_shader_never_fades() {
        let mut c = Cycle::new(1, 10.0, 2.0, false);
        let s = c.scene(1000.0);
        assert_eq!(s.current.0, 0);
        assert!(s.incoming.is_none());
    }

    #[test]
    fn crossfades_then_advances_in_order() {
        let mut c = Cycle::new(3, 10.0, 2.0, false);
        assert!(c.scene(9.9).incoming.is_none());
        let mid = c.scene(11.0);
        assert_eq!(mid.current.0, 0);
        let (idx, time, alpha) = mid.incoming.unwrap();
        assert_eq!(idx, 1);
        assert!((time - 1.0).abs() < 1e-6 && (alpha - 0.5).abs() < 1e-6);
        // The fade ends at t=12; shader 1's clock started with its fade (t=10).
        let after = c.scene(12.5);
        assert_eq!(after.current.0, 1);
        assert!((after.current.1 - 2.5).abs() < 1e-6);
        assert!(after.incoming.is_none());
        assert_eq!(c.scene(25.0).current.0, 2);
    }

    #[test]
    fn shuffle_never_repeats_immediately() {
        let mut c = Cycle::new(4, 4.0, 1.0, true);
        let mut last = c.scene(0.0).current.0;
        for i in 1..200 {
            let cur = c.scene(i as f64 * 4.0 + 1.5).current.0;
            assert_ne!(cur, last);
            last = cur;
        }
    }

    #[test]
    fn disabled_cycle_stays_put() {
        let mut c = Cycle::new(3, 0.0, 2.0, false);
        let s = c.scene(500.0);
        assert_eq!(s.current.0, 0);
        assert!(s.incoming.is_none());
    }
}
