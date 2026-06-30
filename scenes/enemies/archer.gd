extends EnemyBase

@onready var detection_area: Area2D = $AnimatedSprite2D/DetectionArea
@onready var shoot_timer: Timer = $ShootTimer

@export var projectile_scene: PackedScene

var shoot_cooldown: float = 1.5
var can_shoot: bool = true
var is_shooting: bool = false

func _ready() -> void:
	super()
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	anim.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	if health.is_dead():
		return
	if is_shooting:
		velocity.x = 0
		move_and_slide()
		return
	var target := _get_target()
	if target:
		velocity.x = 0
		move_and_slide()
		if can_shoot:
			_shoot()
		return
	super(delta)

func _shoot() -> void:
	if health.is_dead():
		return
	is_shooting = true
	can_shoot = false
	shoot_timer.start(shoot_cooldown)
	var anim_name = "attack" if anim.sprite_frames.has_animation("attack") else "idle"
	anim.play(anim_name)

func _spawn_projectile() -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.get_node("Projectiles").add_child(projectile, true)
	projectile.global_position = global_position
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_other_animation_finished() -> void:
	if anim.animation == "attack":
		is_shooting = false

func _on_hurt_finished() -> void:
	is_shooting = false
	can_shoot = false
	shoot_timer.start(_get_animation_duration("hurt"))

#xd
func _get_animation_duration(anim_name: String) -> float:
	var frame_count = anim.sprite_frames.get_frame_count(anim_name)
	var fps = anim.sprite_frames.get_animation_speed(anim_name)
	return frame_count / fps

func _on_frame_changed() -> void:
	if anim.animation == "attack" and anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:
		_spawn_projectile()
