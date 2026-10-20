class_name PlayerInput
extends MultiplayerSynchronizer


const BASE_SENSITIVITY: float = 0.0025


@export var player: Player

@export var direction := Vector2.ZERO
@export var view_direction := Vector2.ZERO
@export var sprinting: bool = false
@export var jumping: bool = false


func _ready():
	# Only process for the local player.
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		process_mode = PROCESS_MODE_DISABLED
		
		
func _unhandled_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseMotion:
		if player.menu.is_open():
			return
		
		if not player.capturing_cursor:
			return
		
		var movement: Vector2 = input_event.relative
		movement *= BASE_SENSITIVITY
		movement *= Settings.sensitivity
		view_direction -= movement
		view_direction.y = clamp(
				view_direction.y,
				-PI / 2,
				PI / 2
		)
		get_viewport().set_input_as_handled()
		return


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"sprint"):
		set_sprint.rpc(not sprinting)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"jump") and not jumping:
		jump.rpc()
		get_viewport().set_input_as_handled()
		return
	
	
func _process(_delta: float) -> void:
	direction = Input.get_vector(
			&"move_left",
			&"move_right",
			&"move_forward",
			&"move_backward"
	)
	
	
@rpc("call_local", "reliable")
func jump() -> void:
	jumping = true
	

@rpc("call_local", "reliable")
func set_sprint(is_sprinting: bool) -> void:
	sprinting = is_sprinting
