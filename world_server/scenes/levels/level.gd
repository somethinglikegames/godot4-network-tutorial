extends Node3D

const SPAWN_RANDOM := 5.0

@onready var players := $Players


func _ready() -> void:
	for id in multiplayer.get_peers():
		add_player(id)
	get_multiplayer().peer_connected.connect(add_player)
	get_multiplayer().peer_disconnected.connect(del_player)


func _exit_tree():
	get_multiplayer().peer_connected.disconnect(add_player)
	get_multiplayer().peer_disconnected.disconnect(del_player)


func add_player(id: int) -> void:
	var character := preload("res://scenes/levels/player.tscn").instantiate()
	character.player = id
	# Randomize character position
	var pos := Vector2.from_angle(randf() * 2 * PI)
	character.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	character.name = str(id)
	players.add_child(character, true)


func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()
