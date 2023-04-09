extends Node

var login_screen := preload("res://scenes/gui/login_screen.tscn")

var gateway_server : Node
var world_server : Node
var world_server_data : NetworkConnectionData
var rtt_timer : Timer



func _ready() -> void:
	_load_login_screen()


func _load_login_screen() -> void:
	for c in get_children():
		c.queue_free()
	var instance = login_screen.instantiate()
	instance.login = _login
	add_child(instance)


func _login(gw_server: NetworkConnectionData, wrld_server: NetworkConnectionData, username: String, password: String) -> void:
	world_server_data = wrld_server
	gateway_server = Node.new()
	gateway_server.name = "GatewayServer"
	add_child(gateway_server)
	gateway_server.set_script(load("res://scenes/network/gateway_server.gd"))
	get_tree().set_multiplayer(SceneMultiplayer.new(), ^"/root/Main/GatewayServer")
	gateway_server.gateway_server = gw_server
	gateway_server.callback = _login_callback
	gateway_server.login_to_server(username, password)


func _login_callback(return_code: int, token: String) -> void:
	gateway_server.queue_free()
	gateway_server = null
	if return_code == OK:
		print("Current Token is: %s" % token)
		world_server = Node.new()
		world_server.name = "WorldServer"
		add_child(world_server)
		world_server.set_script(load("res://scenes/network/world_server.gd"))
		get_tree().set_multiplayer(SceneMultiplayer.new(), ^"/root/Main/WorldServer")
		world_server.world_server = world_server_data
		world_server.callback = _world_server_callback
		world_server.login_to_server(token)
	else :
		print("Something went wrong…")
		get_node("LoginScreen").reset()


func _world_server_callback(return_code: int) -> void:
	if return_code == OK:
		print("Login to world server was successful")
		rtt_timer = Timer.new()
		add_child(rtt_timer)
		rtt_timer.timeout.connect(_on_rtt_timer_timeout)
		rtt_timer.start(5)
		# Add further game logic
	else:
		gateway_server.queue_free()
		gateway_server = null
		print("Login to world server failed")
		get_node("LoginScreen").reset()


func _on_rtt_timer_timeout() -> void:
	if world_server:
		print("RTT: %f" % world_server.get_rtt())
