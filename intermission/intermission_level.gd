class_name IntermissionLevel
extends Node3D

@onready var spawn_point: Node3D = %SpawnPoint
@onready var void_hitbox: Area3D = %Void


func _ready() -> void:
	void_hitbox.body_entered.connect(_on_body_enter_void)


func _on_body_enter_void(body: Node3D) -> void:
	if body is Player:
		body.global_position = spawn_point.global_position
		body.velocity = Vector3.ZERO
		body.global_rotation = Vector3.ZERO
