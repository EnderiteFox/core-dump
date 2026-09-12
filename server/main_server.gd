extends Node


signal lobby_list_updated(lobbies: Array[LobbyInfo])
signal lobby_created(port: int)


const PORT: int = 25765
const MAX_CLIENTS: int = 10

const MIN_PORT: int = 25766
const MAX_PORT: int = 25800

const GAME_INSTANCE_SCENE: PackedScene = preload("uid://cgocrhnt6ganf")


var servers: Array[GameInstance]


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		# Not initialized on clients
		return
	
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	self.multiplayer.multiplayer_peer = peer
	
	
func _on_peer_connected(_id: int) -> void:
	pass


@rpc("any_peer", "call_remote", "reliable")
func create_lobby(lobby_name: String, max_players: int) -> void:
	if lobby_name.is_empty():
		push_error("Received an empty name")
		return
	
	var lobby_info := LobbyInfo.new()
	lobby_info.lobby_name = lobby_name
	lobby_info.max_players = max_players
	lobby_info.port = get_available_port()
	
	var game_instance: GameInstance = GAME_INSTANCE_SCENE.instantiate()
	game_instance.set_lobby_info(lobby_info)
	
	game_instance.server_ended.connect(close_lobby.bind(game_instance))
	
	servers.append(game_instance)
	var node := Node3D.new()
	node.add_child(game_instance)
	self.add_child(node)
	
	_on_lobby_created.rpc_id(multiplayer.get_remote_sender_id(), lobby_info.port)
	
	
func close_lobby(instance: GameInstance) -> void:
	var parent_node: Node3D = instance.get_parent()
	self.remove_child(parent_node)
	servers.erase(instance)
	parent_node.queue_free()


func get_available_port() -> int:
	var used_ports: Array[int]
	for server in servers:
		used_ports.append(server.get_lobby_info().port)
		
	var curr_port: int = MIN_PORT
	while curr_port <= MAX_PORT and curr_port in used_ports:
		curr_port += 1
		
	return -1 if curr_port > MAX_PORT else curr_port


@rpc("any_peer", "call_remote", "reliable")
func update_lobbies() -> void:
	var infos: Array[Dictionary]
	for lobby in servers:
		infos.append(lobby.get_lobby_info().to_dict())
	_on_lobbies_updated.rpc_id(multiplayer.get_remote_sender_id(), infos)
	
	
@rpc("authority", "call_remote", "reliable")
func _on_lobbies_updated(lobbies: Array[Dictionary]) -> void:
	var deserialized: Array[LobbyInfo] = []
	for lobby in lobbies:
		deserialized.append(LobbyInfo.from_dict(lobby))
	lobby_list_updated.emit(deserialized)
	
	
@rpc("authority", "call_remote", "reliable")
func _on_lobby_created(port: int) -> void:
	lobby_created.emit(port)
