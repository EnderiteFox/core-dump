shader_type spatial;
render_mode unshaded, world_vertex_coords;

varying vec3 world_normal;

void vertex() {
    world_normal = NORMAL;
}

void fragment() {
    ALBEDO = abs(world_normal).rgb;
}
