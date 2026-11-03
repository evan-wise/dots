// Shared library prepended to every shader: the Gruvbox dark palette plus
// noise helpers, so all wallpapers stay in one color family.
const vec3 BG0H   = vec3(0.114, 0.125, 0.129);  // #1d2021
const vec3 BG0    = vec3(0.157, 0.157, 0.157);  // #282828
const vec3 BG1    = vec3(0.235, 0.220, 0.212);  // #3c3836
const vec3 BG2    = vec3(0.314, 0.286, 0.271);  // #504945
const vec3 FG     = vec3(0.922, 0.859, 0.698);  // #ebdbb2
const vec3 RED    = vec3(0.800, 0.141, 0.114);  // #cc241d
const vec3 GREEN  = vec3(0.596, 0.592, 0.102);  // #98971a
const vec3 YELLOW = vec3(0.843, 0.600, 0.129);  // #d79921
const vec3 BLUE   = vec3(0.271, 0.522, 0.533);  // #458588
const vec3 PURPLE = vec3(0.694, 0.384, 0.525);  // #b16286
const vec3 AQUA   = vec3(0.408, 0.616, 0.416);  // #689d6a
const vec3 ORANGE = vec3(0.839, 0.365, 0.055);  // #d65d0e

// Smooth, looping ramp through the accent colors. t is any float; every 1.0
// moves to the next accent.
vec3 accent(float t) {
    vec3 c[6] = vec3[6](BLUE, AQUA, GREEN, YELLOW, ORANGE, PURPLE);
    t = mod(t, 6.0);
    int i = int(floor(t));
    return mix(c[i], c[(i + 1) % 6], smoothstep(0.0, 1.0, fract(t)));
}

// Pixel coordinates -> centered coordinates where y spans [-0.5, 0.5].
vec2 centered(vec2 fc) {
    return (fc - 0.5 * iResolution.xy) / iResolution.y;
}

vec3 vignette(vec3 col, vec2 uv) {
    return col * (0.75 + 0.25 * (1.0 - smoothstep(0.2, 1.3, length(uv))));
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + 7.0;
        a *= 0.5;
    }
    return v;
}
