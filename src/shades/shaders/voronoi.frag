// Animated Voronoi cells (Inigo Quilez's exact-border formulation): each cell
// gets an accent tint, shaded toward its drifting seed, with lit borders.
void mainImage(out vec4 o, in vec2 fc) {
    vec2 p = centered(fc) * 4.5;
    vec2 n = floor(p), f = fract(p);

    // Pass 1: nearest seed.
    float md = 8.0;
    vec2 mr = vec2(0.0), mid = vec2(0.0);
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 s = 0.5 + 0.5 * sin(iTime * 0.3 + 6.2831 * hash22(n + g));
            vec2 r = g + s - f;
            float d = dot(r, r);
            if (d < md) { md = d; mr = r; mid = n + g; }
        }
    }

    // Pass 2: distance to the nearest cell border.
    float bd = 8.0;
    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 s = 0.5 + 0.5 * sin(iTime * 0.3 + 6.2831 * hash22(n + g));
            vec2 r = g + s - f;
            if (dot(mr - r, mr - r) > 1e-5)
                bd = min(bd, dot(0.5 * (mr + r), normalize(r - mr)));
        }
    }

    vec3 tint = accent(hash21(mid) * 6.0 + iTime * 0.02);
    vec3 col = mix(BG0, tint * 0.5, 0.55 + 0.35 * (1.0 - sqrt(md)));
    float edge = 1.0 - smoothstep(0.0, 0.06, bd);
    col = mix(col, FG * 0.5, edge * 0.55);
    o = vec4(vignette(col, centered(fc)), 1.0);
}
