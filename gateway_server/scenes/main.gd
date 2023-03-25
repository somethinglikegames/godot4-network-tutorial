extends Node

@onready var authentication_server := $AuthenticationServer
@onready var gateway_server := $GatewayServer


func _ready() -> void:
	get_tree().set_multiplayer(SceneMultiplayer.new(),
		^"/root/Main/AuthenticationServer")
	get_tree().set_multiplayer(SceneMultiplayer.new(),
		^"/root/Main/GatewayServer")
	gateway_server.shutdown_hook = _quit
	gateway_server.authentication_server = authentication_server
	gateway_server.startup()
	authentication_server.shutdown_hook = _quit
	authentication_server.gateway_server = gateway_server
	authentication_server.startup()


func _quit(error_code: int) -> void:
	print("Shutting down, error_code: %d" % error_code)
	gateway_server.shutdown()
	authentication_server.shutdown()
	get_tree().quit(error_code)
