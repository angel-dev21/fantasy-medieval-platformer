extends Node

@export var max_health: int

var current_health: int

signal health_changed(current: int, max: int)
signal died()

func _ready() -> void:
	current_health = max_health

func is_dead() -> bool:
	return current_health <= 0

func take_damage(amount: int) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		rpc_id(1, "_request_damage", amount)
		return
	_apply_damage(amount)
	if Network.mode == "multi":
		rpc("_apply_damage", amount)

@rpc("any_peer", "call_remote")
func _request_damage(amount: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_damage(amount)
	rpc("_apply_damage", amount)

@rpc("any_peer", "call_remote")
func _apply_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()
