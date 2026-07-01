extends ItemBase

func _try_collect(body: Node2D) -> void:
	var health := body.get_node_or_null("Health")
	if health == null:
		return
	if health.current_health < health.max_health:
		health.heal(1)
		_consume()
