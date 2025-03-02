extends Node2D

var map_scale = Vector2(1, 1)
var map_offset = Vector2(0, 0)
var map_width = 0
var map_height = 0
var screen_width = 0
var screen_height = 0
var map_container = null

var geojson_data = null
var projected_polygons = []
var projector = RobinsonProjection.new()
var current_meridian = 0.0

# Map dimensions in projection units
var projection_width = 2.0  # Robinson projection spans approx -1 to 1 in x
var camera_ref = null
var last_camera_x = 0
var rotation_speed = 2.5  # Adjust as needed
var rotate_left = false
var rotate_right = false

var current_zoom = 1.0
var last_zoom_level = 1.0
var max_simplification = 10.0  # Maximum simplification factor
var min_simplification = 1.0   # Minimum simplification (full detail)

var screen_polygons = []  # To store pre-calculated screen coordinates

# Projection optimization variables
var needs_projection = false
var projection_timer = 0.0
var projection_interval = 1.0/15.0  # Limit to 15 projections per second for continuous rotation

func _ready():
    Engine.max_fps = 30  # Limit to 30 FPS
    screen_width = get_viewport_rect().size.x
    screen_height = get_viewport_rect().size.y

    # Calculate appropriate scale for the map
    map_scale = Vector2(screen_width / 2.0, screen_height / 2.0)

    geojson_data = load_geojson("res://layers/landNoProjection.geojson")
    project_with_meridian(current_meridian)

    # Get reference to camera
    await get_tree().process_frame
    camera_ref = get_viewport().get_camera_2d()
    if camera_ref:
        last_camera_x = camera_ref.global_position.x
        current_zoom = camera_ref.zoom.x
        last_zoom_level = current_zoom

func _draw():
    if screen_polygons.size() == 0:
        return
    
    var line_width = max(1.0, 2.0 / current_zoom)
    var line_color = Color(0.5, 0.5, 0.5, 1.0)
    var max_line_length = screen_width * 0.6  # Add back the maximum line length check
    
    # Combine polygons into fewer polylines
    var combined_points = []
    var current_group = []
    var group_count = 0
    
    for screen_points in screen_polygons:
        if screen_points.size() < 2:
            continue
            
        # Add points with distance checking
        var last_added_point = null
        
        for i in range(screen_points.size()):
            var point = screen_points[i]
            
            # Check distance for line segments
            if last_added_point != null:
                var distance = last_added_point.distance_to(point)
                if distance > max_line_length:
                    # If too long, add a break
                    current_group.append(Vector2(NAN, NAN))
                    last_added_point = null
                    continue
            
            # Add the point and update last_added_point
            current_group.append(point)
            last_added_point = point
        
        # Add a visual break between polygons
        current_group.append(Vector2(NAN, NAN))
        last_added_point = null
        
        # If we've accumulated enough points, flush the group
        group_count += 1
        if group_count >= 25:  # Adjust this number based on performance
            combined_points.append(current_group)
            current_group = []
            group_count = 0
    
    # Add any remaining points
    if current_group.size() > 0:
        combined_points.append(current_group)
    
    # Draw the combined polylines
    for points in combined_points:
        draw_polyline(points, line_color, line_width)

func transform_to_screen(point):
    # Robinson projection spans roughly -1 to 1 in x, scale to screen
    var x = (point.x * map_scale.x) + (screen_width / 2)
    var y = (-point.y * map_scale.y) + (screen_height / 2)
    return Vector2(x, y)

func project_with_meridian(meridian):
    current_meridian = meridian
    projected_polygons = []
    screen_polygons = []
    
    # Get the current simplification factor (now a floating point value)
    var simplification_factor = get_detail_level_for_zoom(current_zoom)
    
    for polygon in geojson_data.polygons:
        # Simplify polygon based on detail level
        var simplified_polygon = simplify_polygon(polygon, simplification_factor)
        
        # Project the simplified polygon
        var projected = projector.project_polygon(simplified_polygon, current_meridian)
        projected_polygons.append(projected)
        
        # Transform to screen coordinates
        var screen_points = []
        for point in projected:
            screen_points.append(transform_to_screen(point))
        screen_polygons.append(screen_points)
    
    queue_redraw()

func simplify_polygon(polygon, factor):
    if factor <= 1.0:
        return polygon  # No simplification needed
    
    var simplified = []
    var step = int(factor)
    
    # Handle fractional steps by sometimes using a larger step
    var fractional_part = factor - step
    var accumulator = 0.0
    
    for i in range(0, polygon.size()):
        # Add the first point always
        if i == 0:
            simplified.append(polygon[i])
            continue
            
        # Add the fractional part to the accumulator
        accumulator += fractional_part
        
        # If we've accumulated enough or if it's time for a regular step
        if i % step == 0 or accumulator >= 1.0:
            simplified.append(polygon[i])
            
            # Reduce accumulator when we use its value
            if accumulator >= 1.0:
                accumulator -= 1.0
    
    # Always include the last point to ensure the polygon closes properly
    var last_idx = polygon.size() - 1
    if simplified.size() > 0 and simplified[simplified.size() - 1] != polygon[last_idx]:
        simplified.append(polygon[last_idx])
    
    return simplified

func get_detail_level_for_zoom(zoom_level):
    # Calculate a smooth interpolation factor based on zoom
    # zoom_level: 0.05 (closest) to 5.0 (furthest)
    
    # Define the range for interpolation
    var max_zoom_for_max_detail = 0.2   # When to start reducing detail
    var min_zoom_for_min_detail = 3.0   # When to reach minimum detail
    
    if zoom_level <= max_zoom_for_max_detail:
        # Full detail at close zoom
        return min_simplification
    elif zoom_level >= min_zoom_for_min_detail:
        # Minimum detail at far zoom
        return max_simplification
    else:
        # Smoothly interpolate between detail levels
        var t = (zoom_level - max_zoom_for_max_detail) / (min_zoom_for_min_detail - max_zoom_for_max_detail)
        
        # Use ease-in-out smoothing 
        t = smoothstep(0.0, 1.0, t)
        
        # Calculate the simplification factor
        return lerp(min_simplification, max_simplification, t)

func _process(delta):
    # Keep input detection in _process
    rotate_left = Input.is_action_pressed("ui_left")
    rotate_right = Input.is_action_pressed("ui_right")
    
    var needs_update = false
    
    # Update meridian based on rotation input
    if rotate_left:
        current_meridian += rotation_speed
        if current_meridian > 180:
            current_meridian -= 360
        needs_update = true
    
    if rotate_right:
        current_meridian -= rotation_speed
        if current_meridian < -180:
            current_meridian += 360
        needs_update = true
    
    # Check for zoom changes
    if camera_ref:
        var new_zoom = camera_ref.zoom.x
        
        # Check if zoom has changed significantly
        if abs(new_zoom - current_zoom) > 0.01:
            current_zoom = new_zoom
            
            # With our fluid detail system, we always update when zoom changes
            needs_update = true
            last_zoom_level = current_zoom
    
    # Throttle projection updates
    if needs_update:
        projection_timer += delta
        
        # For zoom changes, update immediately
        if current_zoom != last_zoom_level:
            project_with_meridian(current_meridian)
            projection_timer = 0
        # For rotation, throttle updates
        elif projection_timer >= projection_interval:
            project_with_meridian(current_meridian)
            projection_timer = 0

func load_geojson(file_path):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        var json_text = file.get_as_text()
        file.close()
        var json = JSON.new()
        var error = json.parse(json_text)
        if error == OK:
            var geojson_data = json.data
            return process_geojson(geojson_data)
        else:
            print("JSON Parse Error: ", json.get_error_message())
    else:
        print("Couldn't open GeoJSON file: ", file_path)
    return null

func process_geojson(data):
    var result = {"polygons": []}

    for feature in data.features:
        if feature.geometry.type == "Polygon":
            for ring in feature.geometry.coordinates:
                var polygon = []
                for coord in ring:
                    # GeoJSON format is [longitude, latitude]
                    polygon.append(Vector2(coord[0], coord[1]))
                result.polygons.append(polygon)
        elif feature.geometry.type == "MultiPolygon":
            for poly in feature.geometry.coordinates:
                for ring in poly:
                    var polygon = []
                    for coord in ring:
                        polygon.append(Vector2(coord[0], coord[1]))
                    result.polygons.append(polygon)

    return result
