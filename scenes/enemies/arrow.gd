extends Area2D

var speed: float = 300.0
var move_direction: float = 1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_direction(dir: float) -> void:
	move_direction = dir
	$Sprite2D.scale.x = dir

func _physics_process(delta: float) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	global_position.x += move_direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	if body.is_in_group("world"):
		queue_free()
	elif body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
