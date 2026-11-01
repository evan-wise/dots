-- Author: Evan Wise
-- Revision Date: 2026-08-23

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal         = "wezterm"
local password_manager = "keepassxc"
local file_manager     = "thunar"
local menu             = "hyprlauncher --toggle"
local browser          = "vivaldi --password-store=gnome-libsecret"
local take_screenshot  = "env XDG_CURRENT_DESKTOP=sway flameshot gui"

------------------
---- COLORS -----
------------------

local color_accent1  = "rgba(d3869bee)"
local color_accent2  = "rgba(83a598ee)"
local color_inactive = "rgba(928374aa)"

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user start hyprland-session.target")
    hl.exec_cmd(terminal, { workspace = "1" })
    hl.exec_cmd(browser, { workspace = "2" })
    hl.exec_cmd("obsidian", { workspace = "special:magic" })
    hl.exec_cmd(password_manager, { workspace = "special:magic" })
end)

-- Old config ran `systemctl --user stop hyprland-session.target` on exec-shutdown.
hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop hyprland-session.target")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 4,

        border_size = 2,

        col = {
            active_border   = { colors = { color_accent1, color_accent2 }, angle = 45 },
            inactive_border = color_inactive,
        },

        resize_on_border = true,

        layout = "dwindle",
    },

    decoration = {
        rounding         = 8,
        inactive_opacity = 0.8,

        blur = {
            enabled  = true,
            size     = 4,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "default", style = "slidefade" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        disable_hyprland_logo = true,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll      = false,
            clickfinger_behavior = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + SHIFT + code:201", hl.dsp.exec_cmd(menu)) -- Copilot key -> app launcher

hl.bind(mainMod .. " + grave",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F",         hl.dsp.exec_cmd(file_manager))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd(password_manager))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + Escape",    hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("wl-copy $(hyprpicker)"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + Tab",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + Return",         hl.dsp.exec_cmd("dunstctl close"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("dunstctl close-all"))
hl.bind(mainMod .. " + ALT + Return",   hl.dsp.exec_cmd("dunstctl history-pop"))
hl.bind(mainMod .. " + CTRL + Return",  hl.dsp.exec_cmd("dunstctl context"))

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(take_screenshot))

-- Audio keys (PipeWire / wpctl)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),         { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        { locked = true })

-- Brightness keys
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    -- Chromium/Vivaldi restores a "maximized" state on launch, which lands it
    -- on top of the tiled layout until the next relayout. Ignore those requests.
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "devtools-vivaldi",
    match = {
        class = "vivaldi-stable",
        title = "Developer Tools.*",
    },
    float = true,
})
