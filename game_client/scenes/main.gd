extends Node

var login_screen := preload("res://scenes/gui/login_screen.tscn")

var gateway_server : Node
var world_server_data : NetworkConnectionData


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
	if return_code == OK:
		print("Login was successful")
		print("Current Token is: %s" % token)
		# Connect to World Server
	else :
		print("Something went wrong…")
		get_node("LoginScreen").reset()
