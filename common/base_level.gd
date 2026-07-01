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
		var index := 2
		for peer_id in multiplayer.get_peers():
			spawner.spawn({"id": peer_id, "index": index})
			index += 1

func _check_game_over() -> void:
	for p in $Players.get_children():
		var h = p.get_node("Health")
		if not h.is_dead():
			return
	await get_tree().create_timer(3.0).timeout
	# cuando exista pantalla de game over real, cambiar destino:
	# en vez de ir directo al menu, ir a una escena "game_over.tscn"
	# que muestre resultados (oro recolectado, etc.) y desde ahi
	# el jugador decide volver al menu. GameState.reset() deberia
	# moverse a ese punto (despues de mostrar resultados), no aqui.
	rpc("_go_to_main_menu")
	_go_to_main_menu()

@rpc("authority", "call_remote")
func _go_to_main_menu() -> void:
	# cuando haya pantalla de resultados/game over, este reset
	# se debe mover a donde el jugador confirme salir de esa pantalla,
	# no aqui directamente.
	GameState.reset()
	Network.mode = "solo"
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
func _on_peer_connected(id: int) -> void:
	spawner.spawn({"id": id, "index": 2})

func _spawn_player(data: Dictionary) -> Node:
	if $Players.has_node(str(data.id)):
		return null
	var player = PLAYER_SCENE.instantiate()
	player.name = str(data.id)
	player.position = $SpawnPoints.get_node(str(data.index)).position
	if Network.mode == "multi" and multiplayer.is_server():
		player.ready.connect(_connect_player_health.bind(player), CONNECT_ONE_SHOT)
	return player

func _connect_player_health(player: Node) -> void:
	var health = player.get_node("Health")
	health.died.connect(_check_game_over)
