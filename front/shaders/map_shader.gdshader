shader_type canvas_item;

uniform sampler2D map_texture;
uniform vec4 land_color;
uniform vec4 ocean_color;
uniform float zoom_level = 1.0;
uniform vec2 zoom_center = vec2(0.5, 0.5);
uniform float edge_sharpness = 0.05; // Controls the sharpness of land edges

void fragment() {
    // Calculate zoomed UV coordinates
    vec2 centered_uv = UV - zoom_center;
    vec2 zoomed_uv = (centered_uv / zoom_level) + zoom_center;
    
    // Check if we're outside the texture bounds after zoom
    if (zoomed_uv.x < 0.0 || zoomed_uv.x > 1.0 || zoomed_uv.y < 0.0 || zoomed_uv.y > 1.0) {
        COLOR = ocean_color;
    } else {
        // Sample the texture at the zoomed coordinates with improved filtering
        vec4 map_color = texture(map_texture, zoomed_uv);
        
        // Add edge enhancement for crisper boundaries
        float alpha = smoothstep(0.0, edge_sharpness, map_color.a);
        
        // Blend between ocean and land color based on the enhanced alpha
        COLOR = mix(ocean_color, land_color, alpha);
    }
}
