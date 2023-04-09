extends Node

@onready var world_server := $WorldServer


func _ready() -> void:
	get_tree().set_multiplayer(SceneMultiplayer.new(),
		^"/root/Main/WorldServer")
	world_server.startup()
