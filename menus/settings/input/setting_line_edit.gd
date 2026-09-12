class_name SettingLineEdit
extends LineEdit


@export var setting_name: StringName


func _ready() -> void:
	load_setting()
	self.tree_exiting.connect(save_setting)
	self.text_submitted.connect(save_setting.unbind(1))


func load_setting() -> void:
	self.text = Settings.get(setting_name)


func save_setting() -> void:
	Settings.set(setting_name, self.text)
