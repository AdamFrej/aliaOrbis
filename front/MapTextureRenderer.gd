extends RefCounted

# Reference to parent node
var parent_node = null

func setup_renderer(parent):
    parent_node = parent

# Creates a texture containing the rendered world map
func render_map_to_texture(geojson_data, viewport_size):
    if geojson_data.polygons.size() == 0:
        printerr("No polygons found in GeoJSON data")
        return null

    # Setup texture dimensions
    var texture_size = calculate_texture_size(viewport_size)
    print("Creating texture with size: ", texture_size)

    # Create viewport for rendering
    var viewport = create_render_viewport(texture_size)
    var canvas = Node2D.new()
    viewport.add_child(canvas)

    # Project and draw polygons
    var projection_manager = load("res://ProjectionManager.gd").new()
    var bounds = projection_manager.prepare_projection(geojson_data, viewport_size)

    # Set up polygon renderer
    var polygon_renderer = load("res://PolygonRenderer.gd").new()
    polygon_renderer.draw_polygons(geojson_data, canvas, projection_manager.projector, bounds, texture_size)

    # Wait for rendering and get texture
    await parent_node.get_tree().process_frame
    await parent_node.get_tree().process_frame

    var img = viewport.get_texture().get_image()
    var tex = ImageTexture.create_from_image(img)

    viewport.queue_free()
    return tex

func calculate_texture_size(viewport_size):
    var viewport_aspect = viewport_size.x / viewport_size.y
    var texture_width = parent_node.TEXTURE_WIDTH
    var texture_height = int(texture_width / viewport_aspect)
    return Vector2i(texture_width, texture_height)

func create_render_viewport(size):
    var viewport = SubViewport.new()
    parent_node.add_child(viewport)
    viewport.size = size
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    return viewport
