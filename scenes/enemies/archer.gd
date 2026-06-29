extends EnemyBase

@onready var detection_area: Area2D = $AnimatedSprite2D/DetectionArea
@onready var shoot_timer: Timer = $ShootTimer

@export var projectile_scene: PackedScene

var player_in_range: Node2D = null
var can_shoot: bool = true

func _ready() -> void:
	super()
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	anim.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return

	if is_waiting:
		super(delta)
		return

	if player_in_range:
		velocity.x = 0
		move_and_slide()
		if can_shoot:
			_shoot()
	else:
		super(delta)

func _shoot() -> void:
	can_shoot = false
	shoot_timer.start(1.5)
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

func _on_player_entered(body: Node2D) -> void:
	player_in_range = body
	if can_shoot:
		_shoot()

func _on_player_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_frame_changed() -> void:
	if anim.animation == "attack" and anim.frame == 6:
		_spawn_projectile()
