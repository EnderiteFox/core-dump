class_name LobbyMenu
extends Control


var LOBBY_ROW_SCENE: PackedScene = preload("uid://ctvqdo1he25pt")
var POPUP_SCENE: PackedScene = preload("uid://c7rtm01au0jfa")


@onready var connecting_label: Label = %ConnectingToServerLabel
@onready var no_lobby_label: Label = %NoLobbyLabel

@onready var refresh_timer: Timer = %LobbyRefreshTimer
@onready var lobby_list: Control = %LobbyList
@onready var create_lobby_section: Control = %CreateLobbySection
@onready var create_lobby_button: Button = %CreateLobbyButton
@onready var back_button: Button = %BackButton

@onready var host_menu: GenericPopup = %HostMenu


var disconnection_reason: String


func _ready() -> void:
	if not disconnection_reason.is_empty():
		show_disconnection_popup(disconnection_reason)
		
	# Connect to main server
	var mult: MultiplayerAPI = SceneMultiplayer.new()
	get_tree().set_multiplayer(mult, get_tree().root.get_path())
	
	var peer := ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", MainServer.PORT)
	self.multiplayer.multiplayer_peer = peer
	
	self.multiplayer.connected_to_server.connect(_on_server_connected)
	self.multiplayer.server_disconnected.connect(_on_server_disconnected)
	refresh_timer.timeout.connect(_on_lobby_refresh_timeout)
	MainServer.lobby_list_updated.connect(_on_lobby_list_updated)

	create_lobby_button.pressed.connect(_on_create_lobby_pressed)
	back_button.pressed.connect(_on_back_pressed)

	host_menu.exiting.connect(_on_host_menu_closed)
	host_menu.lobby_created.connect(_on_lobby_creation)
	
	
func show_popup(text: String) -> void:
	var popup: GamePopup = POPUP_SCENE.instantiate()
	popup.text = text
	self.add_child(popup)
	
	
func show_disconnection_popup(text: String) -> void:
	show_popup("Disconnected: " + text)
	
	
func _on_server_connected() -> void:
	MainServer.update_lobbies.rpc_id(1)
	refresh_timer.start()
	
	
func _on_server_disconnected() -> void:
	refresh_timer.stop()
	for lobby_row: LobbyRow in lobby_list.get_children().filter(func(child): return child is LobbyRow):
		lobby_row.queue_free()
	
	if not connecting_label.visible:
		connecting_label.visible = true
		create_lobby_section.visible = false
		no_lobby_label.visible = false


func _on_lobby_refresh_timeout() -> void:
	MainServer.update_lobbies.rpc_id(1)


func _on_lobby_list_updated(lobbies: Array[LobbyInfo]) -> void:
	if connecting_label.visible:
		connecting_label.visible = false
		create_lobby_section.visible = true
	
	for child in lobby_list.get_children():
		if child is LobbyRow:
			var lobby_row: LobbyRow = child
			if not lobbies.any(func(lobby): return lobby.port == lobby_row.server_port):
				lobby_row.queue_free()
				continue
		
	for lobby_info in lobbies:
		var found: bool = false
		
		for child in lobby_list.get_children():
			if not child is LobbyRow:
				continue
			
			var lobby_row: LobbyRow = child as LobbyRow
			
			if lobby_row.server_port != lobby_info.port:
				continue
			
			found = true
			lobby_row.set_lobby_info(lobby_info)
		
		if not found:
			var lobby_row: LobbyRow = LOBBY_ROW_SCENE.instantiate()
			lobby_row.ready.connect(lobby_row.set_lobby_info.bind(lobby_info), CONNECT_ONE_SHOT)
			lobby_row.selected.connect(_on_lobby_selected.bind(lobby_row))
			lobby_list.add_child(lobby_row)
			
	no_lobby_label.visible = lobby_list.get_children().filter(func(child): return child is LobbyRow).is_empty()
			
			
func _on_create_lobby_pressed() -> void:
	back_button.shortcut_feedback = false
	host_menu.open()
	
	
func _on_host_menu_closed() -> void:
	back_button.shortcut_feedback = true


func _on_back_pressed() -> void:
	if not host_menu.is_open:
		get_tree().change_scene_to_file("uid://3ggukrllkha7")
			
			
func _on_lobby_selected(lobby_row: LobbyRow) -> void:
	var game_instance_scene: PackedScene = load("uid://cgocrhnt6ganf")
	var game_instance: GameInstance = game_instance_scene.instantiate()
	game_instance.set_lobby_info(lobby_row.get_lobby_info())
	get_tree().change_scene_to_node(game_instance)
	
	
func _on_lobby_creation(lobby_name: String, max_players: int) -> void:
	MainServer.create_lobby.rpc_id(1, lobby_name, max_players)
