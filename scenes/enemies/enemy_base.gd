extends CharacterBody2D
class_name EnemyBase

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: RayCast2D = $AnimatedSprite2D/WallDetector
@onready var floor_detector: RayCast2D = $AnimatedSprite2D/FloorDetector
@onready var health: Node = $Health

var speed: float = 60.0
var direction: float = 1.0
var is_waiting: bool = false
var has_initialized: bool = false
var original_scale_x: float
var players_in_range: Array[Node2D] = []

func _ready() -> void:
	original_scale_x = anim.scale.x
	anim.play("default")
	health.died.connect(_die, CONNECT_ONE_SHOT)
	health.health_changed.connect(_on_health_changed)
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		move_and_slide()
		return
	if not has_initialized:
		has_initialized = true
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
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
	if health.current_health > 0:
		is_waiting = false

func _on_player_entered(body: Node2D) -> void:
	if not players_in_range.has(body):
		players_in_range.append(body)

func _on_player_exited(body: Node2D) -> void:
	players_in_range.erase(body)

func _get_target() -> Node2D:
	for p in players_in_range:
		if is_instance_valid(p) and not p.get_node("Health").is_dead():
			return p
	return null

func _play_idle_animation() -> void:
	anim.play("idle")

func _on_animation_finished() -> void:
	if anim.animation == "hurt":
		if not health.is_dead():
			is_waiting = false
			_on_hurt_finished()
	else:
		_on_other_animation_finished()

func _on_other_animation_finished() -> void:
	pass

func _on_hurt_finished() -> void:
	pass

func _on_health_changed(current: int, max: int) -> void:
	if current > 0 and anim.sprite_frames.has_animation("hurt"):
		is_waiting = true
		anim.play("hurt")

func _die() -> void:
	is_waiting = true
	speed = 0
	wall_detector.enabled = false
	floor_detector.enabled = false
	anim.play("death")
	if Network.mode == "multi" and multiplayer.is_server():
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
