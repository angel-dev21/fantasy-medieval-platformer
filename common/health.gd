extends Node

@export var max_health: int

var current_health: int

signal health_changed(current: int, max: int)
signal damaged()
signal died()
signal revived()

func _ready() -> void:
	current_health = max_health

func is_dead() -> bool:
	return current_health <= 0

func heal(amount: int) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		rpc_id(1, "_request_heal", amount)
		return
	_apply_heal(amount)
	if Network.mode == "multi":
		rpc("_apply_heal", amount)

@rpc("any_peer", "call_remote")
func _request_heal(amount: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_heal(amount)
	rpc("_apply_heal", amount)

@rpc("any_peer", "call_remote")
func _apply_heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

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
	damaged.emit()
	if current_health <= 0:
		died.emit()

func revive() -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		rpc_id(1, "_request_revive")
		return
	_apply_revive()
	if Network.mode == "multi":
		rpc("_apply_revive")

@rpc("any_peer", "call_remote")
func _request_revive() -> void:
	if not multiplayer.is_server():
		return
	_apply_revive()
	rpc("_apply_revive")

@rpc("any_peer", "call_remote")
func _apply_revive() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	revived.emit()
