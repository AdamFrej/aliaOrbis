extends Node

var _client = WebSocketPeer.new()
var _connected = false
var _url = "ws://localhost:8080/game"

# UI References
@onready var message_input = $CanvasLayer/VBoxContainer/MessageInput
@onready var send_button = $CanvasLayer/VBoxContainer/SendButton

func _ready():
    # Connect UI signals
    send_button.pressed.connect(self._on_send_button_pressed)
    connect_to_server()

func _on_send_button_pressed():
    var message = message_input.text
    if message.strip_edges() != "":
        send_message(message)
        message_input.text = ""

func _process(delta):
    # Poll the connection
    _client.poll()
    
    var state = _client.get_ready_state()
    if state == WebSocketPeer.STATE_OPEN:
        if !_connected:
            print("Connected to server!")
            _connected = true
            send_message("Hello from Godot!")
        
        # Check for received messages
        while _client.get_available_packet_count() > 0:
            var packet = _client.get_packet()
            print("Received data: ", packet.get_string_from_utf8())
    
    elif state == WebSocketPeer.STATE_CLOSING:
        # Keep polling to achieve proper close
        pass
    elif state == WebSocketPeer.STATE_CLOSED:
        var code = _client.get_close_code()
        var reason = _client.get_close_reason()
        print("WebSocket closed with code: %d, reason: %s" % [code, reason])
        _connected = false
        # Try to reconnect
        set_process(false)
        await get_tree().create_timer(3.0).timeout
        connect_to_server()
        set_process(true)

func connect_to_server():
    print("Connecting to server...")
    # Reset the connection
    _client.close()
    # Connect to the server
    var err = _client.connect_to_url(_url)
    if err != OK:
        print("Unable to connect to server: ", err)
        return

func send_message(message):
    if _connected:
        _client.send_text(message)
