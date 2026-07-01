extends Node
const PORT = 42069
const MAX_PLAYERS = 2
var mode: String = "solo"
signal connected_to_game
signal connection_failed
signal player_disconnected(id)

func start_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	mode = "multi"
	connected_to_game.emit()

func start_client(ip: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	mode = "multi"

func _on_server_disconnected() -> void:
	mode = "solo"
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_connected_to_server() -> void:
	connected_to_game.emit()

func _on_connection_failed() -> void:
	mode = "solo"
	connection_failed.emit()

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)
