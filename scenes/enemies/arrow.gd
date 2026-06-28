extends Area2D

@export var speed: float = 300.0

var move_direction: float = 1.0

func _ready():
	body_entered.connect(_on_body_entered)

func set_direction(dir: float):
	move_direction = dir
	$Sprite2D.scale.x = dir

func _physics_process(delta):
	global_position.x += move_direction * speed * delta

func _on_body_entered(body: Node2D):
	if body.is_in_group("world"):
		queue_free()
	elif body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
