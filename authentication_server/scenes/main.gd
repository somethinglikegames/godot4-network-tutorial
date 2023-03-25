extends Node

@onready var authentication_server := $AuthenticationServer


func _ready() -> void:
	get_tree().set_multiplayer(SceneMultiplayer.new(),
		^"/root/Main/AuthenticationServer")
	authentication_server.startup()
