class_name Player
extends CharacterBody3D


@warning_ignore("unused_signal")
signal leaving_game

signal wall_run_start
signal wall_run_end


const MOVE_SPEED: float = 1.5
const SPRINT_SPEED: float = 3.0

const ACCELERATION: float = 7.0
const DESCELERATION_MULT: float = 7.0
const AIR_DESCELERATION_MULT: float = 5.0
const JUMP_VELOCITY: float = 3.0

const WALL_RUN_MAX_ANGLE: float = deg_to_rad(105)
const WALL_RUN_MIN_ANGLE: float = deg_to_rad(-60)
const WALL_JUMP_STRENGTH: float = 5.0
const WALL_RUN_RAYCAST_DISTANCE: float = 0.3
const WALL_RUN_MAX_TIME: float = 2.0
const WALL_RUN_FALLOFF_GRAVITY_REDUCTION: float = 0.25
const WALL_RUN_MIN_WALL_VERTICAL_ANGLE: float = deg_to_rad(-10)
const WALL_RUN_MAX_WALL_VERTICAL_ANGLE: float = deg_to_rad(20)
const WALL_RUN_COOLDOWN: float = 0.3

# Set by the authority, synchronized on spawn.
@export var player_id: int = 1:
	set(id):
		player_id = id
		# Give authority over the player input to the appropriate peer.
		%PlayerInput.set_multiplayer_authority(id)


@onready var menu: EscapeMenu = %EscapeMenu
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera
@onready var mesh: Node3D = %PlayerMesh
@onready var input: PlayerInput = %PlayerInput

@onready var right_wall_run_raycast: RayCast3D = %RightWallRunRaycast
@onready var left_wall_run_raycast: RayCast3D = %LeftWallRunRaycast

var is_local: bool = false
var capturing_cursor: bool = true
var gravity: float = ProjectSettings.get(&"physics/3d/default_gravity")
var wall_run_direction := WallRunDirection.NONE
var can_wall_run: bool = true
var wall_run_time: float = 0.0
var wall_run_cooldown_timer: SceneTreeTimer = null


func _ready() -> void:
	right_wall_run_raycast.target_position.x = WALL_RUN_RAYCAST_DISTANCE
	left_wall_run_raycast.target_position.x = -WALL_RUN_RAYCAST_DISTANCE
	
	wall_run_start.connect(_on_wall_run_start)
	wall_run_end.connect(_on_wall_run_end)
	
	if player_id == multiplayer.get_unique_id():
		# Local initialization
		is_local = true
		camera.make_current()
		mesh.queue_free()
		mesh = null
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		menu.closed.connect(_on_menu_closed)
	else:
		# Non-local initialization
		mesh.visible = true
		menu.queue_free()
		menu = null


func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	
	if event.is_action_pressed(&"open_menu") and not menu.visible:
		menu.open()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed(&"toggle_cursor"):
		capturing_cursor = not capturing_cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if capturing_cursor else Input.MOUSE_MODE_VISIBLE)
		get_viewport().set_input_as_handled()
		return
		
		
func _physics_process(delta: float) -> void:
	# Handle movement
	
	# Wall run
	var wall_run_normal: Vector3 = _handle_wall_run()
	if wall_run_direction != WallRunDirection.NONE:
		wall_run_time += delta
		
		if self.is_on_floor():
			# End wall run when touching the ground
			wall_run_direction = WallRunDirection.NONE
			wall_run_end.emit()
	
	# Gravity
	if wall_run_direction != WallRunDirection.NONE:
		if self.is_on_floor():
			# End wall run if touching ground
			wall_run_direction = WallRunDirection.NONE
			wall_run_end.emit()
		if wall_run_time > WALL_RUN_MAX_TIME:
			# Wall run falloff, reduce gravity
			self.velocity.y -= gravity * delta * WALL_RUN_FALLOFF_GRAVITY_REDUCTION
		else:
			# Hold player in the air while wallrunning
			self.velocity.y = 0
	else:
		if not self.is_on_floor():
			# Apply normal gravity
			self.velocity.y -= gravity * delta
		else:
			# Reset velocity when touching ground
			self.velocity.y = 0

	# Velocity
	var direction: Vector3 = (self.transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	var speed: float = SPRINT_SPEED if input.sprinting else MOVE_SPEED
	var horizontal_velocity: Vector3 = self.velocity * Vector3(1, 0, 1)
	if direction:
		horizontal_velocity = horizontal_velocity.move_toward(direction * speed, ACCELERATION * delta)
	else:
		var desceleration: float = DESCELERATION_MULT if self.is_on_floor() else AIR_DESCELERATION_MULT
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, desceleration * delta)
	self.velocity.x = horizontal_velocity.x
	self.velocity.z = horizontal_velocity.z
		
	# Jump
	if input.jumping:
		# Wall jump
		if wall_run_direction != WallRunDirection.NONE:
			var wall_jump_velocity: Vector3 = Vector3(wall_run_normal)
			wall_jump_velocity.y = 1
			wall_jump_velocity = wall_jump_velocity.normalized() * WALL_JUMP_STRENGTH
			velocity.y = wall_jump_velocity.y
			wall_jump_velocity.y = 0
			velocity += wall_jump_velocity
			wall_run_direction = WallRunDirection.NONE
			wall_run_end.emit()
		elif self.is_on_floor():
			# Normal ground jump
			velocity.y = JUMP_VELOCITY
	input.jumping = false

	# Camera movement
	self.rotation.y = input.view_direction.x
	camera_pivot.rotation.x = clamp(
			input.view_direction.y,
			-PI / 2,
			PI / 2
	)
	
	move_and_slide()
	
	
# Handles the wall run detection
# Returns the angle of the wall the player is running on, or Vector2.ZERO if the player is not wall running
func _handle_wall_run() -> Vector3:
	# Detect wall run
	var prev_wall_run_direction: WallRunDirection = wall_run_direction
	var collision_normal: Vector3
	
	# Can't wall run if on cooldown
	# Can't wall run if not sprinting
	# Can't wall run if moving up
	if not can_wall_run or not input.sprinting or self.velocity.y > 0:
		if prev_wall_run_direction != WallRunDirection.NONE:
			wall_run_direction = WallRunDirection.NONE
			wall_run_end.emit()
		return Vector3.ZERO

	if prev_wall_run_direction == WallRunDirection.NONE:
		# Detect start of wall run
		if left_wall_run_raycast.is_colliding():
			collision_normal = left_wall_run_raycast.get_collision_normal()
			if _check_wall_run_wall_direction(Vector3(collision_normal)):
				wall_run_direction = WallRunDirection.LEFT
				wall_run_start.emit()
				return collision_normal
		
		if right_wall_run_raycast.is_colliding():
			collision_normal = right_wall_run_raycast.get_collision_normal()
			if _check_wall_run_wall_direction(Vector3(collision_normal)):
				wall_run_direction = WallRunDirection.RIGHT
				wall_run_start.emit()
				return collision_normal
			
		return Vector3.ZERO
		
	var wall_run_raycast: RayCast3D = right_wall_run_raycast\
		if prev_wall_run_direction == WallRunDirection.RIGHT\
		else left_wall_run_raycast

	if not wall_run_raycast.is_colliding():
		wall_run_direction = WallRunDirection.NONE
		wall_run_end.emit()
		return Vector3.ZERO
	
	# Check that we can still wall run
	collision_normal = wall_run_raycast.get_collision_normal()
	if not _check_wall_run_wall_direction(Vector3(collision_normal)):
		wall_run_direction = WallRunDirection.NONE
		wall_run_end.emit()
		return Vector3.ZERO
	
	return collision_normal


# Validates the angle of the wall run (vertical angle and angle with of the wall with the player)
func _check_wall_run_wall_direction(wall_normal: Vector3) -> bool:
	var wall_vertical_angle: float = atan(wall_normal.y) * 2
	
	if wall_vertical_angle < WALL_RUN_MIN_WALL_VERTICAL_ANGLE or wall_vertical_angle > WALL_RUN_MAX_WALL_VERTICAL_ANGLE:
		return false
	
	
	var player_direction: Vector3 = (Vector3.FORWARD * self.transform.basis).normalized()
	wall_normal.y = 0
	wall_normal = wall_normal.normalized()
	wall_normal *= -1
	var wall_angle: float = player_direction.angle_to(wall_normal)
	
	if wall_angle < WALL_RUN_MIN_ANGLE or wall_angle > WALL_RUN_MAX_ANGLE:
		return false
	
	return true


func _on_wall_run_start() -> void:
	wall_run_time = 0.0


func _on_wall_run_end() -> void:
	if wall_run_cooldown_timer != null:
		wall_run_cooldown_timer.timeout.disconnect(_on_wall_run_cooldown_ended)

	can_wall_run = false
	wall_run_cooldown_timer = get_tree().create_timer(WALL_RUN_COOLDOWN)
	wall_run_cooldown_timer.timeout.connect(_on_wall_run_cooldown_ended)
	wall_run_time = 0.0
		
		
func _on_wall_run_cooldown_ended() -> void:
	can_wall_run = true
	
	
func _on_menu_closed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if capturing_cursor else Input.MOUSE_MODE_VISIBLE)
	
	
enum WallRunDirection {
	NONE,
	LEFT,
	RIGHT
}
