shader_type spatial;
render_mode unshaded, world_vertex_coords;

uniform vec3 edge_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float main_color_intensity = 0.125;
uniform float secondary_color_intensity = 0.03;
uniform float secondary_line_offset = 0.25;
uniform float line_width = 0.003;
uniform float line_spacing = 0.25;
uniform float speed = 0.05;

varying vec3 world_pos;
varying vec3 vertex_normal;

void vertex() {
    world_pos = VERTEX;
    vertex_normal = NORMAL;
}

void fragment() {
    ALBEDO = vec3(0.0);
    
    // Apply grid
    if ((
        mod(world_pos.x - TIME * speed, line_spacing * secondary_line_offset) < line_width * secondary_line_offset
            && abs(vertex_normal.x) < 0.99
    ) || (
        mod(world_pos.y - TIME * speed, line_spacing * secondary_line_offset) < line_width * secondary_line_offset
            && abs(vertex_normal.y) < 0.99
    ) || (
        mod(world_pos.z - TIME * speed, line_spacing * secondary_line_offset) < line_width * secondary_line_offset
            && abs(vertex_normal.z) < 0.99)
    ) {
        ALBEDO = edge_color * secondary_color_intensity;
    }

    if ((mod(world_pos.x + TIME * speed, line_spacing) < line_width && abs(vertex_normal.x) < 0.99)
            || (mod(world_pos.y + TIME * speed, line_spacing) < line_width && abs(vertex_normal.y) < 0.99)
            || (mod(world_pos.z + TIME * speed, line_spacing) < line_width && abs(vertex_normal.z) < 0.99)) {
        ALBEDO = edge_color * main_color_intensity;
    }
}
