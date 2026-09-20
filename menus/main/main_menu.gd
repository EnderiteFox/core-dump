extends Control

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton

@onready var settings_menu: SettingsMenu = %SettingsMenu

@onready var username_input: LineEdit = %UsernameInput

const SETTINGS_MENU_ANIMATION_TIME: float = 0.25
const PLAY_MENU_SPACING: int = 10

var settings_tween: Tween = null
var host_tween: Tween = null


func _ready() -> void:
	Settings.load_settings()
	settings_button.pressed.connect(_open_settings_menu)
	settings_menu.exiting.connect(_close_settings_menu)
	exit_button.pressed.connect(get_tree().quit)
	play_button.pressed.connect(_on_play_pressed)
	username_input.text_changed.connect(_on_username_changed)
	username_input.text = Settings.username
	
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed:
			username_input.release_focus()


func _open_settings_menu() -> void:
	if settings_tween != null:
		settings_tween.kill()
		
	settings_tween = create_tween()
	settings_tween.set_parallel(true)
	settings_tween.tween_property(
			settings_menu, 
			"modulate", 
			Color.WHITE, 
			SETTINGS_MENU_ANIMATION_TIME
	)
	settings_tween.tween_property(
			settings_menu,
			"offset_transform_position_ratio",
			Vector2.ZERO,
			SETTINGS_MENU_ANIMATION_TIME
	)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
	settings_menu.open = true
	
	
func _close_settings_menu() -> void:
	if settings_tween != null:
		settings_tween.kill()
		
	settings_tween = create_tween()
	settings_tween.set_parallel(true)
	settings_tween.tween_property(
			settings_menu,
			"modulate",
			Color.TRANSPARENT,
			SETTINGS_MENU_ANIMATION_TIME
	)
	settings_tween.tween_property(
			settings_menu,
			"offset_transform_position_ratio",
			Vector2.DOWN,
			SETTINGS_MENU_ANIMATION_TIME
	)\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_IN)
	settings_menu.open = false
	
	
func _on_play_pressed() -> void:
	Settings.save_settings()
	get_tree().change_scene_to_file("uid://bf3ph1ps23j8b")


func _on_username_changed(new_username: String) -> void:
	Settings.username = new_username
