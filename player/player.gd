class_name Player
extends CharacterBody3D


@onready var menu: EscapeMenu = %EscapeMenu


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_menu") and not menu.visible:
		menu.open()
