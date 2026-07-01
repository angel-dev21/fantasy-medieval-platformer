extends ItemBase

func _try_collect(body: Node2D) -> void:
	GameState.add_gold(1)
	_consume()
