class_name GenericPopup
extends Control


signal exiting


const OPEN_TIME: float = 0.25


var is_open: bool = false
var tween: Tween = null


func _unhandled_key_input(event: InputEvent) -> void:
	if is_open and event.is_action("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if is_open and event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_mask & (MOUSE_BUTTON_WHEEL_DOWN | MOUSE_BUTTON_WHEEL_UP):
			close()
			get_viewport().set_input_as_handled()


func open() -> void:
	if tween != null:
		tween.kill()
		
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.WHITE, OPEN_TIME)
	tween.tween_property(
		self,
		"offset_transform_position_ratio",
		Vector2.ZERO,
		OPEN_TIME
	)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
	is_open = true


func close() -> void:
	if tween != null:
		tween.kill()
		
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, OPEN_TIME)
	tween.tween_property(
			self,
			"offset_transform_position_ratio",
			Vector2.DOWN,
			OPEN_TIME
	)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN)
	is_open = false
	exiting.emit()
