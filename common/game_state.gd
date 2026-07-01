extends Node

var gold: int = 0
signal gold_changed(amount: int)

func reset() -> void:
	gold = 0
	gold_changed.emit(gold)

func add_gold(amount: int) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		rpc_id(1, "_request_add_gold", amount)
		return
	_apply_add_gold(amount)
	if Network.mode == "multi":
		rpc("_apply_add_gold", amount)

@rpc("any_peer", "call_remote")
func _request_add_gold(amount: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_add_gold(amount)
	rpc("_apply_add_gold", amount)

@rpc("any_peer", "call_remote")
func _apply_add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
