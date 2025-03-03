extends RefCounted

var projector = null

func prepare_projection(geojson_data, viewport_size):
    # Initialize the projector
    projector = RobinsonProjection.new()

    # Find the best meridian for projection
    var best_meridian = find_best_central_meridian(geojson_data)
    print("Using central meridian: ", best_meridian)

    # Calculate bounds and adjust for aspect ratio
    var bounds = calculate_projection_bounds(geojson_data)
    adjust_bounds_for_aspect_ratio(bounds, viewport_size.x / viewport_size.y)

    return bounds

func find_best_central_meridian(geojson_data):
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

    return best_meridian

func calculate_projection_bounds(geojson_data):
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
    return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}

func adjust_bounds_for_aspect_ratio(bounds, viewport_aspect):
    var data_width = bounds.max_x - bounds.min_x
    var data_height = bounds.max_y - bounds.min_y
    var data_aspect = data_width / data_height

    if data_aspect > viewport_aspect:
        # Data is wider than viewport, adjust height
        var new_height = data_width / viewport_aspect
        var diff = new_height - data_height
        bounds.min_y -= diff / 2
        bounds.max_y += diff / 2
    else:
        # Data is taller than viewport, adjust width
        var new_width = data_height * viewport_aspect
        var diff = new_width - data_width
        bounds.min_x -= diff / 2
        bounds.max_x += diff / 2

    return bounds
