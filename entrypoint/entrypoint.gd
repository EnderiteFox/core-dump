extends Node


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		# Dedicated server
		pass
	else:
		# Client
		get_tree().change_scene_to_file.call_deferred("uid://3ggukrllkha7")
