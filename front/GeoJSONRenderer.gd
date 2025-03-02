extends Node

var size = Vector2(2048, 1024)  # Size of the render texture
var land_color = Color(0.5, 0.5, 0.5)
var ocean_color = Color(0.2, 0.2, 0.8)

func render_geojson(geojson_path):
    # Create a new image
    var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    img.fill(ocean_color)
    
    # Load and process GeoJSON
    var geojson_data = load_geojson(geojson_path)
    var projector = RobinsonProjection.new()
    
    # Draw each polygon
    for polygon in geojson_data.polygons:
        var projected = projector.project_polygon(polygon)
        draw_polygon(img, projected, land_color)
    
    # Create and return texture
    return ImageTexture.create_from_image(img)

func load_geojson(path):
    var loader = load("res://aliaOrbis/front/load_geojson.gd").new()
    return loader.load_geojson(path)

func draw_polygon(img, points, color):
    # Convert projected points to image coordinates
    var image_points = []
    for point in points:
        # Convert from Robinson projection (-1 to 1) to image coordinates
        var x = int((point.x + 1.0) * 0.5 * size.x)
        var y = int((1.0 - (point.y + 1.0) * 0.5) * size.y)  # Flip Y
        
        # Ensure point is in bounds
        x = clamp(x, 0, size.x - 1)
        y = clamp(y, 0, size.y - 1)
        
        image_points.append(Vector2(x, y))
    
    # Draw filled polygon
    # This is a naive scanline algorithm - you might want a more efficient implementation
    if image_points.size() < 3:
        return
        
    # Find the bounding box
    var min_y = size.y
    var max_y = 0
    for p in image_points:
        min_y = min(min_y, p.y)
        max_y = max(max_y, p.y)
    
    # Scan each line in the bounding box
    for y in range(min_y, max_y + 1):
        var intersections = []
        
        # Find intersections with all edges
        for i in range(image_points.size()):
            var j = (i + 1) % image_points.size()
            var p1 = image_points[i]
            var p2 = image_points[j]
            
            # Skip horizontal lines
            if p1.y == p2.y:
                continue
                
            # Check if the line crosses this y-coordinate
            if (y >= p1.y and y < p2.y) or (y >= p2.y and y < p1.y):
                # Calculate x-coordinate of intersection
                var x = p1.x + (p2.x - p1.x) * (y - p1.y) / (p2.y - p1.y)
                intersections.append(int(x))
        
        # Sort intersections
        intersections.sort()
        
        # Fill between pairs of intersections
        for i in range(0, intersections.size(), 2):
            if i + 1 < intersections.size():
                for x in range(intersections[i], intersections[i+1] + 1):
                    img.set_pixel(x, y, color)
