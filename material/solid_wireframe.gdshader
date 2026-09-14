shader_type spatial;
render_mode unshaded, world_vertex_coords;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap, repeat_disable;

uniform vec3 edge_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float normal_threshold = 0.2;
uniform float depth_threshold = 0.0001;

uniform float main_color_intensity = 0.125;
uniform float secondary_color_intensity = 0.01;
uniform float secondary_line_offset = 0.25;
uniform float line_width = 0.003;
uniform float line_spacing = 0.25;
uniform float speed = 0.05;

varying vec3 world_pos;
varying vec3 vertex_normal;

vec2 pixel_to_screen_uv(vec2 viewport_size, vec2 pixel) {
    return vec2(pixel.x / viewport_size.x, pixel.y / viewport_size.y);
}

float vec_angle(vec3 a, vec3 b) {
    float dot = dot(a, b);
    float a_len = length(a);
    float b_len = length(b);
    return abs(acos(dot / (a_len * b_len)));
}

float vec_avg(vec3 a) {
    return (a.r + a.g + a.b) / 3.0;
}

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
    
    // Edge detection
    vec2 iuv = vec2(SCREEN_UV.x * VIEWPORT_SIZE.x, SCREEN_UV.y * VIEWPORT_SIZE.y);
    
    vec3 left = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(-0.5, 0))).rgb;
    float left_depth = vec_avg(texture(DEPTH_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(-0.5, 0))).rgb);
    vec3 right = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.5, 0))).rgb;
    float right_depth = vec_avg(texture(DEPTH_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.5, 0))).rgb);
    
    vec3 top = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, -0.5))).rgb;
    float top_depth = vec_avg(texture(DEPTH_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, -0.5))).rgb);
    vec3 bottom = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0.5))).rgb;
    float bottom_depth = vec_avg(texture(DEPTH_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0.5))).rgb);
    
    if (vec_angle(left, right) > normal_threshold || vec_angle(top, bottom) > normal_threshold) {
        ALBEDO = edge_color;
    }
    else if (distance(left_depth, right_depth) > depth_threshold
            || distance(top_depth, bottom_depth) > depth_threshold) {
        ALBEDO = edge_color;
    }
}
