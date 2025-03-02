extends MeshInstance2D

var geojson_loader = null
var polygon_data = []

# Zoom control variables
var zoom_level = 1.0
var min_zoom = 0.1
var max_zoom = 5000.0
var zoom_step = 0.1
var zoom_center = Vector2(0.5, 0.5)
var is_dragging = false
var drag_start_position = Vector2()
var drag_start_zoom_center = Vector2()

func _ready():
    # Create a simple rectangular mesh (quad) that covers the viewport
    var mesh = QuadMesh.new()
    
    # Set the mesh size to match the viewport
    var viewport_size = get_viewport_rect().size
    mesh.size = viewport_size
    
    # Position the mesh to center of the screen
    position = viewport_size / 2
    
    # Assign the mesh
    self.mesh = mesh
    
    # Create a shader material
    var material = ShaderMaterial.new()
    var shader = Shader.new()
    
    # Load the shader code
    shader.code = load_shader_code("res://shaders/map_shader.gdshader")
    material.shader = shader
    
    # Assign the material to the mesh
    self.material = material
    
    # Load and pre-render the map texture
    geojson_loader = load("res://load_geojson.gd").new()
    var geojson_data = geojson_loader.load_geojson("res://layers/landNoProjection.geojson")
    print("Loaded GeoJSON with ", geojson_data.polygons.size(), " polygons")
    var map_texture = await render_map_to_texture(geojson_data, viewport_size)
    
        # After setting up the material, set initial zoom parameters
    material.set_shader_parameter("zoom_level", zoom_level)
    material.set_shader_parameter("zoom_center", zoom_center)
    
    # Set shader parameters
    material.set_shader_parameter("map_texture", map_texture)
    material.set_shader_parameter("land_color", Color.html("#efefed"))
    material.set_shader_parameter("ocean_color", Color.html("#e2e8e3"))

func load_shader_code(path):
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        var code = file.get_as_text()
        file.close()
        return code
    return ""

func render_map_to_texture(geojson_data, viewport_size):
    # Use the same aspect ratio as the viewport
    var viewport_aspect = viewport_size.x / viewport_size.y
    var texture_width = 8192
    var texture_height = int(texture_width / viewport_aspect)
    var texture_size = Vector2i(texture_width, texture_height)
    
    print("Creating texture with size: ", texture_size)
    
    # Create a temporary SubViewport
    var viewport = SubViewport.new()
    add_child(viewport)
    viewport.size = texture_size
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    
    var canvas = Node2D.new()
    viewport.add_child(canvas)
    
    var projector = RobinsonProjection.new()
    
    # Try different central meridians for better coverage
    var central_meridians = [0.0, 10.0, 20.0]
    var best_meridian = 0.0
    var max_visible_points = 0
    
    # Find the central meridian that shows the most land
    for meridian in central_meridians:
        var visible_points = 0
        
        for polygon in geojson_data.polygons:
            var projected = projector.project_polygon(polygon)
            visible_points += projected.size()
        
        if visible_points > max_visible_points:
            max_visible_points = visible_points
            best_meridian = meridian
    
    print("Using central meridian: ", best_meridian)
    
    # Determine the bounds of all polygons with the best meridian
    var min_x = INF
    var max_x = -INF
    var min_y = INF
    var max_y = -INF
    
    for polygon in geojson_data.polygons:
        var projected = projector.project_polygon(polygon)
        
        for point in projected:
            min_x = min(min_x, point.x)
            max_x = max(max_x, point.x)
            min_y = min(min_y, point.y)
            max_y = max(max_y, point.y)
    
    print("Coordinate bounds - X: ", min_x, " to ", max_x, " | Y: ", min_y, " to ", max_y)
    
    # Calculate aspect ratios to maintain proportions
    var data_width = max_x - min_x
    var data_height = max_y - min_y
    var data_aspect = data_width / data_height
    
    # Adjust the texture's internal coordinate system to match the viewport's aspect ratio
    if data_aspect > viewport_aspect:
        # Data is wider than viewport, adjust height
        var new_height = data_width / viewport_aspect
        var diff = new_height - data_height
        min_y -= diff / 2
        max_y += diff / 2
    else:
        # Data is taller than viewport, adjust width
        var new_width = data_height * viewport_aspect
        var diff = new_width - data_width
        min_x -= diff / 2
        max_x += diff / 2
    
    # Scale to fit the texture with some margin
    var scale_x = texture_size.x / (max_x - min_x) * 0.9
    var scale_y = texture_size.y / (max_y - min_y) * 0.9
    var scale = min(scale_x, scale_y)
    
    # Position to center
    var offset_x = (texture_size.x - ((max_x - min_x) * scale)) / 2.0
    var offset_y = (texture_size.y - ((max_y - min_y) * scale)) / 2.0
    
    print("Drawing all ", geojson_data.polygons.size(), " polygons...")
    var polygons_drawn = 0
    
    # Track which polygons are drawn for each continent
    var continent_drawn = {
        "North America": false,
        "South America": false,
        "Europe": false,
        "Africa": false,
        "Asia": false,
        "Oceania/Australia": false,
        "Antarctica": false
    }
    
    # Define rough continent bounding boxes (lon/lat)
    var continent_boxes = {
        "North America": Rect2(Vector2(-170, 15), Vector2(60, 70)),
        "South America": Rect2(Vector2(-80, -60), Vector2(40, 75)),
        "Europe": Rect2(Vector2(-10, 35), Vector2(40, 35)),
        "Africa": Rect2(Vector2(-20, -40), Vector2(55, 80)),
        "Asia": Rect2(Vector2(25, 0), Vector2(145, 80)),
        "Oceania/Australia": Rect2(Vector2(110, -50), Vector2(70, 30)),
        "Antarctica": Rect2(Vector2(-180, -90), Vector2(360, 25))
    }
    
    # Draw all polygons using project_polygon_continuous for better handling of edges
    for polygon in geojson_data.polygons:
        var projected = projector.project_polygon(polygon)
        
        # Check which continent this polygon belongs to
        var continent = "Unknown"
        for point in polygon:
            for cont_name in continent_boxes:
                var box = continent_boxes[cont_name]
                if point.x >= box.position.x && point.x <= (box.position.x + box.size.x) && point.y >= box.position.y && point.y <= (box.position.y + box.size.y):
                    continent = cont_name
                    continent_drawn[cont_name] = true
                    break
            if continent != "Unknown":
                break
        
        var points = []
        for point in projected:
            var x = ((point.x - min_x) * scale) + offset_x
            var y = ((point.y - min_y) * scale) + offset_y
            points.append(Vector2(x, y))
        
        var poly = Polygon2D.new()
        poly.polygon = points
        poly.color = Color(1, 1, 1, 1)
        canvas.add_child(poly)
        polygons_drawn += 1
    
    # Report on continents drawn
    print("Continents drawn:")
    for continent in continent_drawn:
        print("  ", continent, ": ", "Yes" if continent_drawn[continent] else "No")
    
    print("Finished drawing ", polygons_drawn, " polygons")
    
    # Wait for rendering
    await get_tree().process_frame
    await get_tree().process_frame
    
    # Get the texture
    var img = viewport.get_texture().get_image()
    var tex = ImageTexture.create_from_image(img)
    # Add this after getting the texture but before cleanup
    var debug_dir = "user://debug"
    var dir = DirAccess.open("user://")
    if !dir.dir_exists(debug_dir):
        dir.make_dir(debug_dir)

    var debug_path = debug_dir + "/map_debug.png"
    img.save_png(debug_path)
    print("Saved debug image to: ", debug_path)
    
    # Cleanup
    viewport.queue_free()
    
    return tex
    
func _input(event):
    # Handle mouse wheel for zooming
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_in(event.position)
            get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_out(event.position)
            get_viewport().set_input_as_handled()
        # Handle panning with mouse drag
        elif event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                is_dragging = true
                drag_start_position = event.position
                drag_start_zoom_center = zoom_center
            else:
                is_dragging = false
    
    # Handle mouse movement for panning
    if event is InputEventMouseMotion and is_dragging:
        pan_map(event.position)

func zoom_in(mouse_pos):
    if zoom_level < max_zoom:
        # Convert mouse position to UV coordinates (0-1 range)
        var viewport_size = get_viewport_rect().size
        var mouse_uv = mouse_pos / viewport_size
        
        # Calculate new zoom center to zoom toward mouse position
        zoom_center = lerp(zoom_center, mouse_uv, 0.1)
        
        # Increase zoom level
        zoom_level = min(zoom_level + zoom_step, max_zoom)
        material.set_shader_parameter("zoom_level", zoom_level)
        material.set_shader_parameter("zoom_center", zoom_center)

func zoom_out(mouse_pos):
    if zoom_level > min_zoom:
        # Decrease zoom level
        zoom_level = max(zoom_level - zoom_step, min_zoom)
        
        # If we're at min zoom, reset center
        if zoom_level == min_zoom:
            zoom_center = Vector2(0.5, 0.5)
        
        material.set_shader_parameter("zoom_level", zoom_level)
        material.set_shader_parameter("zoom_center", zoom_center)

func pan_map(current_mouse_pos):
    # Calculate mouse movement in viewport space
    var viewport_size = get_viewport_rect().size
    
    # Reverse the direction by swapping positions (current_mouse_pos - drag_start_position)
    var movement = (current_mouse_pos - drag_start_position) / viewport_size
    
    # Adjust movement based on zoom level - panning should feel consistent at all zoom levels
    movement = movement / zoom_level
    
    # Calculate new zoom center
    var new_center = drag_start_zoom_center - movement  # Note the subtraction here
    
    # Limit panning to keep some content on screen
    var margin = 0.1 / zoom_level  # Smaller margin at higher zoom
    zoom_center.x = clamp(new_center.x, margin, 1.0 - margin)
    zoom_center.y = clamp(new_center.y, margin, 1.0 - margin)
    
    # Update shader
    material.set_shader_parameter("zoom_center", zoom_center)
