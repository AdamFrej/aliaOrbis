extends MeshInstance2D

## Constants for map rendering
const TEXTURE_WIDTH = 16384
const MARGIN_FACTOR = 0.9  # 10% margin around map
const ZOOM_FACTOR = 1.1
const MIN_ZOOM = 0.1
const MAX_ZOOM = 5000.0
const DEFAULT_ZOOM_CENTER = Vector2(0.5, 0.5)

# Resource loaders
var map_renderer = null
var geojson_loader = null

# Zoom control variables
var zoom_level = 1.0
var min_zoom = MIN_ZOOM
var max_zoom = MAX_ZOOM
var zoom_factor = ZOOM_FACTOR
var zoom_center = DEFAULT_ZOOM_CENTER
var is_dragging = false
var drag_start_position = Vector2()
var drag_start_zoom_center = Vector2()

func _ready():
    setup_mesh()
    setup_shader()
    load_and_render_map()

func setup_mesh():
    # Create a simple rectangular mesh (quad) that covers the viewport
    var mesh = QuadMesh.new()
    var viewport_size = get_viewport_rect().size
    mesh.size = viewport_size
    position = viewport_size / 2
    self.mesh = mesh

func setup_shader():
    var material = ShaderMaterial.new()
    var shader = Shader.new()
    shader.code = load_shader_code("res://shaders/map_shader.gdshader")
    material.shader = shader
    material.set_shader_parameter("zoom_level", zoom_level)
    material.set_shader_parameter("zoom_center", zoom_center)
    self.material = material

func load_and_render_map():
    var viewport_size = get_viewport_rect().size
    geojson_loader = load("res://load_geojson.gd").new()
    var geojson_data = geojson_loader.load_geojson("res://layers/landNoProjection.geojson")
    print("Loaded GeoJSON with ", geojson_data.polygons.size(), " polygons")

    map_renderer = load("res://MapTextureRenderer.gd").new()
    map_renderer.setup_renderer(self)

    var map_texture = await map_renderer.render_map_to_texture(geojson_data, viewport_size)
    if map_texture:
        material.set_shader_parameter("map_texture", map_texture)
        material.set_shader_parameter("land_color", Color.html("#efefed"))
        material.set_shader_parameter("ocean_color", Color.html("#e0e7e2"))
    else:
        printerr("Failed to create map texture")

func load_shader_code(path):
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        var code = file.get_as_text()
        file.close()
        return code
    else:
        printerr("Failed to open shader file: ", path)
        return ""

func _input(event):
    if event is InputEventMouseButton:
        handle_mouse_button(event)
    elif event is InputEventMouseMotion and is_dragging:
        pan_map(event.position)

func handle_mouse_button(event):
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
        zoom_in(event.position)
        get_viewport().set_input_as_handled()
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        zoom_out(event.position)
        get_viewport().set_input_as_handled()
    elif event.button_index == MOUSE_BUTTON_LEFT:
        handle_left_mouse_button(event)

func handle_left_mouse_button(event):
    if event.pressed:
        is_dragging = true
        drag_start_position = event.position
        drag_start_zoom_center = zoom_center
    else:
        is_dragging = false

func zoom_in(mouse_pos):
    if zoom_level < max_zoom:
        # Increase zoom level
        zoom_level = min(zoom_level * zoom_factor, max_zoom)

        material.set_shader_parameter("zoom_level", zoom_level)
        material.set_shader_parameter("zoom_center", zoom_center)

func zoom_out(mouse_pos):
    if zoom_level > min_zoom:
        # Decrease zoom level
        zoom_level = max(zoom_level / zoom_factor, min_zoom)

        material.set_shader_parameter("zoom_level", zoom_level)
        material.set_shader_parameter("zoom_center", zoom_center)

func pan_map(current_mouse_pos):
    # Calculate mouse movement in viewport space
    var viewport_size = get_viewport_rect().size

    # Create movement vector
    var movement = Vector2()
    # For horizontal: drag right -> map moves right (direct relationship)
    movement.x = (current_mouse_pos.x - drag_start_position.x) / viewport_size.x

    # For vertical: drag down -> map moves up (inverted relationship)
    movement.y = (drag_start_position.y - current_mouse_pos.y) / viewport_size.y

    # Adjust movement based on zoom level - panning should feel consistent at all zoom levels
    movement = movement / zoom_level

    # Calculate new zoom center
    var new_center = drag_start_zoom_center - movement

    # Limit panning to keep some content on screen
    var margin = 0.1 / zoom_level  # Smaller margin at higher zoom
    zoom_center.x = clamp(new_center.x, margin, 1.0 - margin)
    zoom_center.y = clamp(new_center.y, margin, 1.0 - margin)

    # Update shader
    material.set_shader_parameter("zoom_center", zoom_center)
