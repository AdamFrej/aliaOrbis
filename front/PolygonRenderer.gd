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

    # Draw all polygons
    for polygon in geojson_data.polygons:
        var projected = projector.project_polygon(polygon)

        var points = []
        for point in projected:
            var x = ((point.x - bounds.min_x) * scale) + offset_x
            var y = ((point.y - bounds.min_y) * scale) + offset_y
            points.append(Vector2(x, y))

        var poly = Polygon2D.new()
        poly.polygon = points
        poly.color = Color(1, 1, 1, 1)
        canvas.add_child(poly)
