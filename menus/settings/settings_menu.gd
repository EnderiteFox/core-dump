class_name SettingsMenu
extends Control

signal exiting

var open: bool = false


func _unhandled_key_input(event: InputEvent) -> void:
	if open and event.is_action("ui_cancel"):
		exiting.emit()
		get_viewport().set_input_as_handled()
		
		
func _gui_input(event: InputEvent) -> void:
	if open and event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_mask & (MOUSE_BUTTON_WHEEL_DOWN | MOUSE_BUTTON_WHEEL_UP):
			exiting.emit()
			get_viewport().set_input_as_handled()
