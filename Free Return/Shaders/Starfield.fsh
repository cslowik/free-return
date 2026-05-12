void main() {
    vec2 uv = v_tex_coord;
    float aspect = u_size.x / max(u_size.y, 1.0);
    vec2 auv = vec2(uv.x * aspect, uv.y);

    vec3 col = u_zoneTint * (0.9 + 0.15 * (1.0 - uv.y));
    // mark auv usage so it isn't optimized out
    col += vec3(0.05) * auv.x;

    gl_FragColor = vec4(col, 1.0);
}
