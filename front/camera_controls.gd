extends Camera2D

var movement_speed = 500
var min_zoom = 0.05  # Changed from 0.1 to allow closer zooming
var max_zoom = 5.0
var zoom_speed = 0.08  # Slightly reduced for smoother zooming
var drag_active = false

func _ready():
    make_current()

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_at_point(zoom * (1 - zoom_speed), event.position)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_at_point(zoom * (1 + zoom_speed), event.position)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            drag_active = event.pressed
                
    elif event is InputEventMouseMotion and drag_active:
        position -= event.relative / zoom

func zoom_at_point(new_zoom, point):
    # Clamp zoom values
    new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
    new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
    
    # Get global position of mouse
    var mouse_pos = get_global_mouse_position()
    
    # Get direction from camera center to mouse
    var dir = mouse_pos - global_position
    
    # Calculate new position to zoom toward mouse
    var offset = dir - dir * (new_zoom.x / zoom.x)
    
    # Apply new zoom and position
    zoom = new_zoom
    global_position += offset

func _process(delta):
    var input_dir = Vector2()
    # Remove left/right controls from camera - these now control map rotation
    if Input.is_action_pressed("ui_down"):
        input_dir.y += 1
    if Input.is_action_pressed("ui_up"):
        input_dir.y -= 1
    
    if input_dir.length() > 0:
        position += Vector2(0, input_dir.y) * movement_speed * delta / zoom.x
        
