extends Node2D

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")

@onready var spawner: MultiplayerSpawner = $PlayerSpawner

func _ready() -> void:
	spawner.spawn_function = _spawn_player
	if Network.mode == "solo":
		var player = _spawn_player({"id": 1, "index": 1})
		$Players.add_child(player)
		return
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		spawner.spawn({"id": 1, "index": 1})

func _on_peer_connected(id: int) -> void:
	spawner.spawn({"id": id, "index": 2})

func _spawn_player(data: Dictionary) -> Node:
	if $Players.has_node(str(data.id)):
		return null
	var player = PLAYER_SCENE.instantiate()
	player.name = str(data.id)
	player.position = $SpawnPoints.get_node(str(data.index)).position
	return player
