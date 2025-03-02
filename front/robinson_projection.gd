class_name RobinsonProjection

# Robinson projection parameters
const X = [0.8487, 0.84751182, 0.84479598, 0.84125159, 0.83666874, 0.83124165, 0.82512717, 0.81854652, 0.81143571, 0.80392055, 0.795, 0.78556246, 0.77536883, 0.76367525, 0.75, 0.73456737, 0.71746482, 0.69849304, 0.67777114, 0.65521889, 0.63082026, 0.60460309, 0.57657901, 0.54677586, 0.51523226]
const Y = [0, 0.0838426, 0.1676852, 0.2515278, 0.3353704, 0.419213, 0.5030556, 0.5868982, 0.6707408, 0.7545834, 0.838426, 0.9222686, 1.0061112, 1.0899538, 1.1737964, 1.257639, 1.3414816, 1.4253242, 1.5091668, 1.5930094, 1.676852, 1.7606946, 1.8445372, 1.9283798, 2.0122224]
const INTERVALS = 5.0

func project_point(lon_lat: Vector2, central_meridian: float = 0.0) -> Vector2:
    var lon = lon_lat.x
    var lat = lon_lat.y
    
    # Normalize longitude relative to central meridian
    lon = lon - central_meridian
    while lon > 180.0:
        lon -= 360.0
    while lon < -180.0:
        lon += 360.0
    
    var phi = abs(lat) * PI / 180.0
    var i = int(phi * 180 / PI / INTERVALS)
    if i >= len(X) - 1:
        i = len(X) - 2
        
    var fraction = (abs(lat) - i * INTERVALS) / INTERVALS
    var x = X[i] + fraction * (X[i + 1] - X[i])
    var y = Y[i] + fraction * (Y[i + 1] - Y[i])
    
    # Adjust x based on longitude
    x = x * lon * PI / 180.0
    
    # Adjust y sign based on latitude
    if lat < 0:
        y = -y
        
    return Vector2(x, y)

func project_polygon(polygon: Array, central_meridian: float = 0.0) -> Array:
    var projected = []
    
    for point in polygon:
        # Try to handle coordinates that might be far outside normal range
        var lon = point.x
        # Normalize to -180 to 180 range
        while lon > 180.0:
            lon -= 360.0
        while lon < -180.0:
            lon += 360.0
            
        var proj_point = project_point(Vector2(lon, point.y), 0.0)
        projected.append(proj_point)
        
    return projected

func project_polygon_continuous(polygon: Array, central_meridian: float = 0.0) -> Array:
    var projected = []
    var prev_point = null
    var prev_proj = null
    
    # First pass: project all points
    for point in polygon:
        var proj = project_point(point, central_meridian)
        
        if prev_point != null:
            # Check for longitude wrapping (a large jump in x value)
            # This indicates crossing the map boundary
            var lon_diff = abs(point.x - prev_point.x)
            if lon_diff > 180:
                # Instead of allowing a jump, we'll extend the previous point
                # If wrapping eastward
                if prev_proj.x < 0 and proj.x > 0:
                    # Add an intermediate point at right edge
                    projected.append(Vector2(1.0, prev_proj.y + (proj.y - prev_proj.y) * 
                                        (1.0 - prev_proj.x) / (proj.x - prev_proj.x)))
                # If wrapping westward
                elif prev_proj.x > 0 and proj.x < 0:
                    # Add an intermediate point at left edge
                    projected.append(Vector2(-1.0, prev_proj.y + (proj.y - prev_proj.y) * 
                                         (-1.0 - prev_proj.x) / (proj.x - prev_proj.x)))
        
        projected.append(proj)
        prev_point = point
        prev_proj = proj
    
    # Handle potential wrap between last and first point
    if polygon.size() > 0 and projected.size() > 0:
        var first_point = polygon[0]
        var last_point = polygon[polygon.size() - 1]
        var first_proj = projected[0]
        var last_proj = projected[projected.size() - 1]
        
        var lon_diff = abs(first_point.x - last_point.x)
        if lon_diff > 180:
            # Similar handling for wrap between last and first point
            if last_proj.x < 0 and first_proj.x > 0:
                projected.append(Vector2(1.0, last_proj.y + (first_proj.y - last_proj.y) * 
                                     (1.0 - last_proj.x) / (first_proj.x - last_proj.x)))
            elif last_proj.x > 0 and first_proj.x < 0:
                projected.append(Vector2(-1.0, last_proj.y + (first_proj.y - last_proj.y) * 
                                      (-1.0 - last_proj.x) / (first_proj.x - last_proj.x)))
    
    return projected
