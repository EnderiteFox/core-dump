class_name GamePopup
extends Control


const FADE_OUT_TIME: float = 0.25


@onready var _label: Label = %PopupText


var tween: Tween = null
var text: String


func _ready() -> void:
	_label.text = text
	
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if tween != null:
			return
		
		tween = self.create_tween()
		tween.tween_property(self, "modulate", Color.TRANSPARENT, FADE_OUT_TIME)
		tween.tween_callback(self.queue_free)
