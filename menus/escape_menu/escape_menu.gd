class_name EscapeMenu
extends Control


const ANIM_OPEN: StringName = &"open"

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var setting_button: Button = %SettingsButton
@onready var leave_button: Button = %LeaveButton

var opening: bool = false


func _ready() -> void:
	self.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)
	setting_button.pressed.connect(_on_settings_button_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)
	
	
func _unhandled_key_input(event: InputEvent) -> void:
	if opening or not self.visible:
		return
	
	if event.is_action_pressed(&"open_menu"):
		close()
	
	
func _gui_input(event: InputEvent) -> void:
	if opening or not self.visible:
		return
	
	if event is InputEventMouseButton and event.is_pressed():
		close()
	
	
func _on_animation_finished(_anim_name: StringName) -> void:
	if not opening:
		self.visible = false
		return
	
	opening = false
	
	
func _on_settings_button_pressed() -> void:
	pass


func _on_leave_button_pressed() -> void:
	get_tree().change_scene_to_file("uid://bf3ph1ps23j8b")


func open() -> void:
	self.visible = true
	self.opening = true
	animation_player.play(ANIM_OPEN)
	
	

func close() -> void:
	animation_player.play_backwards(ANIM_OPEN)
