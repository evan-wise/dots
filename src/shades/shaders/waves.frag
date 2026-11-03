// Layered sine ridges, back to front. Very cheap.
void mainImage(out vec4 o, in vec2 fc) {
    vec2 uv = fc / iResolution.xy;
    float asp = iResolution.x / iResolution.y;
    float aa = 1.5 / iResolution.y;

    vec3 col = mix(BG0H, BG0, uv.y);
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float base = 0.82 - fi * 0.13;
        float y = base
                + 0.050 * sin(uv.x * asp * (2.5 + fi * 0.7) + iTime * (0.10 + 0.03 * fi) + fi * 1.7)
                + 0.025 * sin(uv.x * asp * (6.0 + fi * 1.9) - iTime * 0.08 + fi);
        float m = 1.0 - smoothstep(y - aa, y + aa, uv.y);
        col = mix(col, accent(fi) * (0.25 + 0.05 * fi), m * 0.9);
    }
    o = vec4(col, 1.0);
}
