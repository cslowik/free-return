// Procedural twinkling starfield for SpriteKit (GLSL-ES 1.0).
// Uniforms (set by StarfieldBackground.swift):
//   u_zoneTint  vec3   background base color
//   u_zoneSeed  float  offsets the hash so different zones get different layouts
//   u_size      vec2   sprite size in points (used for aspect correction)

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    vec2 q = vec2(dot(p, vec2(127.1, 311.7)),
                  dot(p, vec2(269.5, 183.3)));
    return fract(sin(q) * 43758.5453);
}

vec3 starLayer(vec2 uv, float density, float starSize, float threshold, float twinkleSpeed) {
    vec2 scaled = uv * density;
    vec2 cell = floor(scaled);
    vec2 frac = fract(scaled);
    vec3 col = vec3(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));
            vec2 ncell = cell + offset + vec2(u_zoneSeed);

            float presence = hash21(ncell);
            if (presence < threshold) {
                vec2 starPos = offset + 0.2 + 0.6 * hash22(ncell + 17.0);
                float dist = length(frac - starPos);

                float baseBrightness = 0.4 + 0.6 * hash21(ncell + 31.0);
                float phase = hash21(ncell + 53.0) * 6.28318;
                float twinkle = 0.65 + 0.35 * sin(u_time * twinkleSpeed + phase);

                float falloff = smoothstep(starSize, 0.0, dist);
                falloff = pow(falloff, 3.0);

                col += vec3(falloff * baseBrightness * twinkle);
            }
        }
    }
    return col;
}

void main() {
    vec2 uv = v_tex_coord;

    // Aspect-correct so stars are circular instead of squashed.
    float aspect = u_size.x / max(u_size.y, 1.0);
    vec2 auv = vec2(uv.x * aspect, uv.y);

    // Subtle vertical gradient: slightly brighter at the bottom.
    vec3 col = u_zoneTint * (0.9 + 0.15 * (1.0 - uv.y));

    // Sparse + bright foreground stars.
    col += starLayer(auv, 18.0, 0.04, 0.35, 1.4) * 1.0;
    // Dense + dim deep-background stars.
    col += starLayer(auv, 36.0, 0.025, 0.5, 1.0) * 0.45;

    gl_FragColor = vec4(col, 1.0);
}
