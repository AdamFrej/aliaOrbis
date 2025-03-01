# aliaOrbis/front/load_geojson.gd
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
var detail_levels = {
	"high": 1.0,    # Full detail
	"medium": 2.0,  # Half the points
	"low": 5.0      # 1/5 of the points
}
var current_detail = "high"

func _ready():
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
func _draw():
	if projected_polygons.size() == 0:
		return
	
	# Adjust line width based on zoom
	var line_width = max(1.0, 2.0 / current_zoom)
	var line_color = Color(0.5, 0.5, 0.5, 1.0)
	
	for polygon in projected_polygons:
		var screen_points = []
		for point in polygon:
			screen_points.append(transform_to_screen(point))
			
		if screen_points.size() >= 2:
			# Maximum allowed distance for a line segment
			var max_line_length = screen_width * 0.6
			
			for i in range(screen_points.size() - 1):
				var distance = screen_points[i].distance_to(screen_points[i + 1])
				if distance < max_line_length:
					draw_line(screen_points[i], screen_points[i + 1], line_color, line_width)
			
			# Connect the last point to the first
			if screen_points.size() > 2:
				var distance = screen_points[screen_points.size() - 1].distance_to(screen_points[0])
				if distance < max_line_length:
					draw_line(screen_points[screen_points.size() - 1], screen_points[0], line_color, line_width)

func transform_to_screen(point):
	# Robinson projection spans roughly -1 to 1 in x, scale to screen
	var x = (point.x * map_scale.x) + (screen_width / 2)
	var y = (-point.y * map_scale.y) + (screen_height / 2)
	return Vector2(x, y)

func project_with_meridian(meridian):
	current_meridian = meridian
	projected_polygons = []
	
	var simplification_factor = detail_levels[current_detail]
	
	for polygon in geojson_data.polygons:
		# Simplify polygon based on detail level
		var simplified_polygon = simplify_polygon(polygon, simplification_factor)
		
		# Project the simplified polygon
		var projected = projector.project_polygon(simplified_polygon, current_meridian)
		projected_polygons.append(projected)
	
	queue_redraw()

func simplify_polygon(polygon, factor):
	if factor <= 1.0:
		return polygon  # No simplification needed
	
	var simplified = []
	for i in range(0, polygon.size(), factor):
		simplified.append(polygon[i])
	
	# Always include the last point to ensure the polygon closes properly
	if simplified.size() > 0 and simplified[simplified.size()-1] != polygon[polygon.size()-1]:
		simplified.append(polygon[polygon.size()-1])
	
	return simplified

func _process(delta):
	# Existing rotation code
	rotate_left = Input.is_action_pressed("ui_left")
	rotate_right = Input.is_action_pressed("ui_right")
	
	if rotate_left:
		current_meridian += rotation_speed
		if current_meridian > 180:
			current_meridian -= 360
		project_with_meridian(current_meridian)
	
	if rotate_right:
		current_meridian -= rotation_speed
		if current_meridian < -180:
			current_meridian += 360
		project_with_meridian(current_meridian)
	
	# Add zoom level checking
	if camera_ref:
		current_zoom = camera_ref.zoom.x
		var new_detail = get_detail_level_for_zoom(current_zoom)
		
		# Only reproject if detail level changed
		if new_detail != current_detail or abs(current_zoom - last_zoom_level) > 0.2:
			current_detail = new_detail
			last_zoom_level = current_zoom
			project_with_meridian(current_meridian)

func get_detail_level_for_zoom(zoom_level):
	if zoom_level < 0.5:  # When zoomed in a lot
		return "high"
	elif zoom_level < 1.0:  # Medium zoom
		return "medium"
	else:  # Zoomed out
		return "low"

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
