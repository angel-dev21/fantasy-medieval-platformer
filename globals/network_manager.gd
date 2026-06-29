extends Node

signal connected_to_game
signal connection_failed
signal player_disconnected(id)

const PORT = 42069
const MAX_PLAYERS = 2

var mode: String = "solo"

func start_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
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
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
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
