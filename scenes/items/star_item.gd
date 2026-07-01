extends ItemBase

func _try_collect(body: Node2D) -> void:
	if Network.mode != "multi":
		return
	var dead_player := _find_dead_player(body)
	if dead_player == null:
		return
	var spawn_pos := body.global_position + Vector2(30, 0)
	dead_player.revive(spawn_pos)
	_consume()

func _find_dead_player(collector: Node2D) -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p == collector:
			continue
		if not is_instance_valid(p):
			continue
		var h := p.get_node_or_null("Health")
		if h and h.is_dead():
			return p
	return null
