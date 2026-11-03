// Parallax starfield drifting over a dim purple/blue nebula, with an
// occasional shooting star. Mostly black, so it is easy on OLED panels.
vec3 starLayer(vec2 uv, float scale, float seed) {
    vec2 p = uv * scale;
    vec2 id = floor(p), f = fract(p) - 0.5;
    float h = hash21(id + seed);
    if (h < 0.7) return vec3(0.0);  // only some cells hold a star
    vec2 off = (hash22(id + seed * 3.1) - 0.5) * 0.6;
    float size = 0.015 + 0.05 * hash21(id + 7.7);
    float twinkle = 0.7 + 0.3 * sin(iTime * (0.5 + 2.0 * h) + h * 50.0);
    float s = (1.0 - smoothstep(0.0, size, length(f - off))) * twinkle;
    vec3 c = mix(FG, accent(h * 6.0), 0.35);
    return c * s;
}

vec3 shootingStar(vec2 uv) {
    const float period = 11.0;
    float slot = floor(iTime / period);
    float t = iTime - slot * period;  // seconds into this slot
    const float life = 1.3;
    if (t > life) return vec3(0.0);
    vec2 start = (hash22(vec2(slot, 3.0)) - 0.5) * vec2(1.2, 0.5) + vec2(-0.2, 0.2);
    vec2 dir = normalize(vec2(1.0, -0.5));
    vec2 pa = uv - (start + dir * t * 0.8);
    float along = -dot(pa, dir);  // distance behind the head
    float perp = abs(dot(pa, vec2(-dir.y, dir.x)));
    float trail = step(0.0, along) * exp(-along * 16.0) * (1.0 - smoothstep(0.0, 0.004, perp));
    return FG * trail * (1.0 - t / life);
}

void mainImage(out vec4 o, in vec2 fc) {
    vec2 uv = centered(fc);

    float neb = fbm(uv * 1.6 + iTime * 0.01);
    vec3 col = mix(BG0H, mix(BLUE, PURPLE, fbm(uv * 1.2 - 3.0)) * 0.3, neb * neb);

    col += starLayer(uv + vec2(iTime * 0.006, 0.0), 14.0, 1.0) * 0.5;
    col += starLayer(uv + vec2(iTime * 0.012, 0.0), 9.0, 2.0) * 0.8;
    col += starLayer(uv + vec2(iTime * 0.024, 0.0), 5.0, 3.0);
    col += shootingStar(uv);
    o = vec4(vignette(col, uv), 1.0);
}
