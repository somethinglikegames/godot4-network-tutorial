extends MultiplayerSynchronizer

@export var jumping := false
@export var switch_color := false
@export var direction := Vector2()

func _ready() -> void:
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())


@rpc("call_local")
func jump() -> void:
	jumping = true


@rpc("call_local")
func color_switch() -> void:
	switch_color = true


func _process(_delta: float) -> void:
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_action_just_pressed("ui_accept"):
		jump.rpc()
	if Input.is_action_just_pressed("ui_focus_next"):
		color_switch.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
