class_name SliderLabel
extends Label


@export var slider: Slider
@export var integer: bool = true


func _ready() -> void:
	slider.value_changed.connect(_on_slider_change)
	_on_slider_change(slider.value)
	
	
func _on_slider_change(value: float) -> void:
	if integer:
		self.text = String.num(value, 0)
	else:
		self.text = String.num(value)
