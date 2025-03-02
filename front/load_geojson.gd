extends Node

# Simple class for loading and processing GeoJSON files
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
