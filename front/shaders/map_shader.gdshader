shader_type canvas_item;

uniform sampler2D map_texture;
uniform vec4 land_color;
uniform vec4 ocean_color;
uniform float zoom_level = 1.0;
uniform vec2 zoom_center = vec2(0.5, 0.5);

void fragment() {
    // Calculate zoomed UV coordinates
    vec2 centered_uv = UV - zoom_center;
    vec2 zoomed_uv = (centered_uv / zoom_level) + zoom_center;

    // Check if we're outside the texture bounds after zoom
    if (zoomed_uv.x < 0.0 || zoomed_uv.x > 1.0 || zoomed_uv.y < 0.0 || zoomed_uv.y > 1.0) {
        COLOR = ocean_color;
    } else {
        // Inside the map - use the texture colors directly
        COLOR = texture(map_texture, zoomed_uv);
    }
}
