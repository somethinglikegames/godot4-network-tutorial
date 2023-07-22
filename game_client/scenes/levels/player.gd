extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const colorToMaterial: Dictionary = { SupportedColors.GREEN: preload("res://materials/green.tres"),
										SupportedColors.BLUE: preload("res://materials/blue.tres"),
										SupportedColors.RED: preload("res://materials/red.tres"),
										}

enum SupportedColors { GREEN, BLUE, RED}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_ready := false

# Set by server (authority), synchronized on spawn
@export var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)
@export var currentColor : SupportedColors = SupportedColors.GREEN:
	set(color):
		currentColor = color
		if is_ready:
			mesh.surface_set_material(0, colorToMaterial[currentColor])

@onready var input = $PlayerInput
@onready var mesh: Mesh = $MeshInstance3D.mesh

func _ready() -> void:
	is_ready = true
	if player == multiplayer.get_unique_id():
		$Camera3D.current = true

func _process(_delta: float) -> void:
	if input.switch_color:
		input.switch_color = false
		match currentColor:
			SupportedColors.GREEN:
				currentColor = SupportedColors.BLUE
			SupportedColors.BLUE:
				currentColor = SupportedColors.RED
			SupportedColors.RED:
				currentColor = SupportedColors.GREEN

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if input.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
	input.jumping = false

	var direction := (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
