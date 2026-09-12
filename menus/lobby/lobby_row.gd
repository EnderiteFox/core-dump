class_name LobbyRow
extends PanelContainer


signal selected


@onready var lobby_name: Label = %LobbyName
@onready var player_count: Label = %PlayerCount
@onready var focused_overlay: Control = %FocusedOverlay


var server_port: int
var focused: bool = false

var _lobby_info: LobbyInfo


func _ready() -> void:
	self.focus_entered.connect(_on_focus)
	self.focus_exited.connect(_on_not_focused)
	
	
func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and focused:
		selected.emit()
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected.emit()
			return
	
	
func _on_focus() -> void:
	focused_overlay.visible = true
	focused = true


func _on_not_focused() -> void:
	focused_overlay.visible = false
	focused = false


func set_lobby_info(info: LobbyInfo) -> void:
	lobby_name.text = info.lobby_name
	player_count.text = str(info.player_count) + " / " + str(info.max_players)
	server_port = info.port
	_lobby_info = info
	

func get_lobby_info() -> LobbyInfo:
	return _lobby_info
