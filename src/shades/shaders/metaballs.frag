// Classic metaballs: summed inverse-square fields, tinted by whichever balls
// contribute most. Colors drift slowly around the accent ramp.
void mainImage(out vec4 o, in vec2 fc) {
    vec2 uv = centered(fc);
    float asp = iResolution.x / iResolution.y;
    vec2 extent = vec2(0.5 * asp - 0.08, 0.38);

    float field = 0.0;
    vec3 tint = vec3(0.0);
    for (int i = 0; i < 7; i++) {
        float fi = float(i);
        vec2 c = extent * vec2(sin(iTime * (0.11 + 0.021 * fi) + fi * 2.3),
                               cos(iTime * (0.09 + 0.017 * fi) + fi * 1.9));
        float r = 0.075 + 0.03 * sin(fi * 1.7);
        float d = r * r / dot(uv - c, uv - c);
        field += d;
        tint += d * accent(fi * 0.9 + iTime * 0.04);
    }
    tint /= max(field, 1e-4);

    float body = smoothstep(0.95, 1.05, field);
    float halo = smoothstep(0.35, 0.95, field) * (1.0 - body);

    vec3 col = mix(BG0H, BG0, 0.5 + uv.y);
    col = mix(col, tint * 0.45, halo * 0.7);
    col = mix(col, tint * 0.85, body);
    col += FG * 0.07 * smoothstep(1.0, 3.5, field) * body;  // soft highlight in the cores
    o = vec4(vignette(col, uv), 1.0);
}
