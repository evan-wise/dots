// Slow domain-warped noise (Inigo Quilez's warping technique) drifting
// through the Gruvbox accents.
void mainImage(out vec4 o, in vec2 fc) {
    vec2 uv = centered(fc);
    float t = iTime * 0.04;
    vec2 p = uv * 2.2;

    vec2 q = vec2(fbm(p + t), fbm(p + vec2(5.2, 1.3) - t));
    vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7, 9.2) + t * 1.5),
                  fbm(p + 3.0 * q + vec2(8.3, 2.8) - t));
    float f = fbm(p + 3.0 * r);

    vec3 col = BG0;
    col = mix(col, BLUE,   smoothstep(0.25, 0.70, f) * 0.55);
    col = mix(col, PURPLE, clamp(length(q), 0.0, 1.0) * 0.35);
    col = mix(col, ORANGE, smoothstep(0.60, 1.00, r.x) * 0.30);
    o = vec4(vignette(col, uv), 1.0);
}
