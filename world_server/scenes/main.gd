extends Node

@onready var world_server := $WorldServer
@onready var spawner := $WorldServer/LevelSpawner
@onready var level := $WorldServer/Level

func _ready() -> void:
	get_tree().set_multiplayer(SceneMultiplayer.new(),
		^"/root/Main/WorldServer")
	world_server.started.connect(change_level.bind(
		load("res://scenes/levels/level.tscn")))
	world_server.startup()

func change_level(scene: PackedScene):
	# Remove old level if any.
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())
