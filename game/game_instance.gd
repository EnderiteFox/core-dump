class_name GameInstance
extends Node3D


signal new_chat_message(message: String)
signal server_ended

signal disconnected(reason: String)


const CHAT_CHANNEL: int = 1
const GAME_EVENT_CHANNEL: int = 2


var _lobby_info: LobbyInfo

var pending_profiles: Dictionary[int, PlayerProfile]
var player_profiles: Dictionary[int, PlayerProfile]
var mult: MultiplayerAPI
var is_server: bool


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		# Dedicated server
		is_server = true
		var peer := ENetMultiplayerPeer.new()
		mult = SceneMultiplayer.new()
		peer.create_server(_lobby_info.port)
		mult.multiplayer_peer = peer
		mult.auth_timeout = 3
		mult.auth_callback = _authenticate_peer
		mult.peer_connected.connect(_on_peer_connected)
		mult.peer_disconnected.connect(_on_peer_disconnected)
		get_tree().set_multiplayer(mult, self.get_parent().get_path())
	else:
		# Client
		is_server = false
		var peer := ENetMultiplayerPeer.new()
		peer.create_client(Settings.server_ip, _lobby_info.port)
		self.multiplayer.multiplayer_peer = peer
		self.multiplayer.auth_callback = func(): pass
		self.multiplayer.peer_authenticating.connect(_authenticate_client)
		
		var player_scene: PackedScene = load("uid://nayrdjp0c8eh")
		var player: Player = player_scene.instantiate()
		self.add_child(player)
		
		self.disconnected.connect(_on_disconnection)
		
		
static func get_current(caller: Node) -> GameInstance:
	var scene_root: Node = caller.get_tree().current_scene
	
	if not scene_root is GameInstance:
		push_error("Tried to get game instance, but the root is not a game instance")
		return null
	
	return scene_root


func _authenticate_peer(peer_id: int, payload: PackedByteArray) -> void:
	var auth_data: Dictionary = JSON.parse_string(payload.get_string_from_utf8())
	var player_profile := PlayerProfile.from_dict(auth_data)
	pending_profiles[peer_id] = player_profile
	
	mult.complete_auth(peer_id)
	

func _authenticate_client(peer_id: int) -> void:
	var player_profile := PlayerProfile.new()
	player_profile.username = Settings.username
	player_profile.level = 1
	self.multiplayer.send_auth(1, JSON.stringify(player_profile.to_dict()).to_utf8_buffer())
	self.multiplayer.complete_auth(peer_id)
	
	
func _on_peer_connected(peer_id: int) -> void:
	if player_profiles.size() >= _lobby_info.max_players:
		send_disconnection.rpc_id(peer_id, "Max players reached")
		return
	
	player_profiles[peer_id] = pending_profiles[peer_id]
	pending_profiles.erase(peer_id)
	
	var encoded_profiles: Dictionary[int, Dictionary]
	for profile_peer_id: int in player_profiles:
		encoded_profiles[profile_peer_id] = player_profiles[profile_peer_id].to_dict()
	send_profile_list.rpc(encoded_profiles)
	
	var player_profile: PlayerProfile = player_profiles[peer_id]
	on_chat_message.rpc("[color=green]" + player_profile.username + " joined the game[/color]")
	
	
func _on_peer_disconnected(peer_id: int) -> void:
	if not peer_id in player_profiles:
		return
	
	var player_profile: PlayerProfile = player_profiles[peer_id]
	on_chat_message.rpc("[color=red]" + player_profile.username + " left the game[/color]")
	player_profiles.erase(peer_id)
	var encoded_profiles: Dictionary[int, Dictionary]
	for profile_peer_id: int in player_profiles:
		encoded_profiles[profile_peer_id] = player_profiles[profile_peer_id].to_dict()
	send_profile_list.rpc(encoded_profiles)
	
	if player_profiles.is_empty():
		server_ended.emit()
		
		
func _on_disconnection(reason: String) -> void:
	var lobby_menu_scene: PackedScene = load("uid://bf3ph1ps23j8b")
	var lobby_menu: LobbyMenu = lobby_menu_scene.instantiate()
	lobby_menu.disconnection_reason = reason
	get_tree().change_scene_to_node(lobby_menu)


func get_lobby_info() -> LobbyInfo:
	_lobby_info.player_count = player_profiles.size()
	return _lobby_info


func set_lobby_info(info: LobbyInfo) -> void:
	_lobby_info = info
	
	
@rpc("authority", "call_remote", "reliable", GAME_EVENT_CHANNEL)
func send_profile_list(profile_list: Dictionary[int, Dictionary]) -> void:
	for peer_id: int in profile_list:
		player_profiles[peer_id] = PlayerProfile.from_dict(profile_list[peer_id])
	
	
@rpc("any_peer", "call_remote", "reliable", CHAT_CHANNEL)
func send_chat_message(message: String) -> void:
	if not is_server:
		return
	
	var peer_id: int = self.multiplayer.get_remote_sender_id()
	
	if not peer_id in player_profiles:
		return
	
	var player_name: String = player_profiles[peer_id].username
	
	on_chat_message.rpc(player_name + ": " + message)
	
	
@rpc("authority", "call_remote", "reliable", CHAT_CHANNEL)
func on_chat_message(message: String) -> void:
	new_chat_message.emit(message)
	
	
@rpc("authority", "call_remote", "reliable", GAME_EVENT_CHANNEL)
func send_disconnection(reason: String) -> void:
	disconnected.emit(reason)
