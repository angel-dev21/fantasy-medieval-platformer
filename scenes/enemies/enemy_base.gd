extends CharacterBody2D
class_name EnemyBase

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: RayCast2D = $AnimatedSprite2D/WallDetector
@onready var floor_detector: RayCast2D = $AnimatedSprite2D/FloorDetector

var speed: float = 60.0
var max_health: int = 1
var current_health: int
var direction: float = 1.0
var is_waiting: bool = false
var original_scale_x: float

func _ready() -> void:
	original_scale_x = anim.scale.x
	current_health = max_health
	anim.play("default")

func _physics_process(delta: float) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		move_and_slide()
		return

	if is_waiting:
		velocity.x = 0
		move_and_slide()
		return

	if wall_detector.is_colliding() or not floor_detector.is_colliding():
		_start_turn()
		return

	anim.play("default")
	velocity.x = direction * speed
	move_and_slide()

func _start_turn() -> void:
	is_waiting = true
	direction = -direction
	anim.scale.x = original_scale_x * direction
	_play_idle_animation()
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self):
		return
	if current_health > 0:
		is_waiting = false

func _play_idle_animation() -> void:
	anim.play("idle")

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	if current_health <= 0:
		_die()

func _die() -> void:
	is_waiting = true
	speed = 0
	wall_detector.enabled = false
	floor_detector.enabled = false
	anim.play("death")
	if Network.mode == "multi":
		rpc("_die_client")
	await anim.animation_finished
	queue_free()

@rpc("authority", "call_remote")
func _die_client() -> void:
	is_waiting = true
	speed = 0
	wall_detector.enabled = false
	floor_detector.enabled = false
	anim.play("death")
	await anim.animation_finished
	queue_free()

@rpc("any_peer", "call_local")
func _take_damage_rpc(amount: int) -> void:
	take_damage(amount)
