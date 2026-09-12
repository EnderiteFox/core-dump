extends Node

const SAVE_PATH: String = "user://settings.ini"

var username: String
var server_ip: String
var server_port: String


func _ready() -> void:
	load_settings()
	self.tree_exiting.connect(save_settings)


func save_settings() -> void:
	var config := ConfigFile.new()
	
	config.set_value("Profile", "username", username)
	config.set_value("Server", "server_ip", server_ip)
	config.set_value("Server", "server_port", server_port)
	
	var error: int = config.save(SAVE_PATH)
	if error:
		push_error("Couldn't save config with error: ", error)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error: int = config.load(SAVE_PATH)
	
	match error:
		Error.OK:
			pass
		Error.ERR_FILE_NOT_FOUND:
			print("Settings not found, using default values")
		_:
			push_error("Failed to load settings")
	
	username = config.get_value("Profile", "username", "")
	server_ip = config.get_value("Server", "server_ip", "127.0.0.1")
	server_port = config.get_value("Server", "server_port", "25765")
