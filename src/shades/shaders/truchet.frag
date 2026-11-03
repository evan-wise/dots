// Truchet tiles: each cell draws one of two quarter-circle arc pairs, chosen
// by a hash, so the arcs knit into endless winding paths. Scrolls slowly;
// a brightness wave travels across the paths.
void mainImage(out vec4 o, in vec2 fc) {
    vec2 uv = centered(fc);
    const float scale = 7.0;
    vec2 p = uv * scale + vec2(iTime * 0.12, iTime * 0.05);
    vec2 id = floor(p);
    vec2 f = fract(p) - 0.5;

    float h = hash21(id);
    if (h > 0.5) f.x = -f.x;

    float d = min(abs(length(f - 0.5) - 0.5), abs(length(f + 0.5) - 0.5));
    float aa = 1.5 * scale / iResolution.y;
    float w = 0.07;
    float line = 1.0 - smoothstep(w - aa, w + aa, d);
    float glow = exp(-d * 9.0);

    float wave = 0.65 + 0.35 * sin(length(id) * 0.45 - iTime * 0.5);
    vec3 c = accent(h * 6.0 + length(id) * 0.08 + iTime * 0.03);

    vec3 col = BG0;
    col += c * glow * 0.12 * wave;
    col = mix(col, c * 0.8 * wave, line * 0.9);
    o = vec4(vignette(col, uv), 1.0);
}
