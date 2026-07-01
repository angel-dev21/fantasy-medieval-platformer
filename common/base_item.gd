extends Area2D
class_name ItemBase

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	if collected:
		return
	if not body.is_in_group("player"):
		return
	_try_collect(body)

func _try_collect(body: Node2D) -> void:
	pass

func _consume() -> void:
	if collected:
		return
	collected = true
	collision.set_deferred("disabled", true)
	if Network.mode == "multi":
		rpc("_consume_client")
	queue_free()

@rpc("authority", "call_remote")
func _consume_client() -> void:
	if collected:
		return
	collected = true
	collision.set_deferred("disabled", true)
	queue_free()
