extends Node

@onready var authentication_server := $AuthenticationServer
@onready var gateway_server := $GatewayServer


func _ready() -> void:
    get_tree().set_multiplayer(SceneMultiplayer.new(),
        ^"/root/Main/AuthenticationServer")
    get_tree().set_multiplayer(SceneMultiplayer.new(),
        ^"/root/Main/GatewayServer")
    gateway_server.startup()
    authentication_server.startup()
