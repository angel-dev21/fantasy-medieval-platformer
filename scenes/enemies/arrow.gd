extends Area2D

@export var damage: int = 1

var speed: float = 300.0
var move_direction: float = 1.0
var lifetime: float = 1.0
var time_alive: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_direction(dir: float) -> void:
	move_direction = dir
	$Sprite2D.scale.x = dir

func _physics_process(delta: float) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	global_position.x += move_direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	if body is TileMapLayer:
		queue_free()
	else:
		var target_health := body.get_node_or_null("Health")
		if target_health:
			target_health.take_damage(damage)
			queue_free()
