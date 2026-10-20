class_name SettingSlider
extends Slider


@export var setting_name: StringName
@export var integer: bool = false


func _ready() -> void:
	load_setting()
	self.tree_exiting.connect(save_setting)
	self.value_changed.connect(save_setting.unbind(1))


func load_setting() -> void:
	self.value = Settings.get(setting_name)


func save_setting() -> void:
	if integer:
		Settings.set(setting_name, int(self.value))
	else:
		Settings.set(setting_name, float(self.value))
