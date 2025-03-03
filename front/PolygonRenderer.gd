extends RefCounted

const MARGIN_FACTOR = 0.9  # 10% margin around map

func draw_polygons(geojson_data, canvas, projector, bounds, texture_size):
    # Scale to fit the texture with some margin
    var scale_x = texture_size.x / (bounds.max_x - bounds.min_x) * MARGIN_FACTOR
    var scale_y = texture_size.y / (bounds.max_y - bounds.min_y) * MARGIN_FACTOR
    var scale = min(scale_x, scale_y)

    # Position to center
    var offset_x = (texture_size.x - ((bounds.max_x - bounds.min_x) * scale)) / 2.0
    var offset_y = (texture_size.y - ((bounds.max_y - bounds.min_y) * scale)) / 2.0

    #First draw the Robinson projection boundary filled with ocean color
    var boundary = projector.calculate_robinson_boundary_polygon()
    var scaled_boundary = []
    for point in boundary:
        var x = ((point.x - bounds.min_x) * scale) + offset_x
        var y = ((point.y - bounds.min_y) * scale) + offset_y
        scaled_boundary.append(Vector2(x, y))

    var ocean = Polygon2D.new()
    ocean.polygon = scaled_boundary
    ocean.color = Color(0.2, 0.5, 0.8, 1)  # Ocean blue
    canvas.add_child(ocean)

    # Then draw all land polygons on top
    for polygon in geojson_data.polygons:
        var projected = projector.project_polygon(polygon)

        var points = []
        for point in projected:
            var x = ((point.x - bounds.min_x) * scale) + offset_x
            var y = ((point.y - bounds.min_y) * scale) + offset_y
            points.append(Vector2(x, y))

        var poly = Polygon2D.new()
        poly.polygon = points
        poly.color = Color(0.75, 0.7, 0.5, 1)  # Land color (beige/tan)
        canvas.add_child(poly)
