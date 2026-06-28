extends EnemyBase

@onready var detection_area: Area2D = $AnimatedSprite2D/DetectionArea
@onready var shoot_timer: Timer = $ShootTimer

@export var projectile_scene: PackedScene

var player_in_range: Node2D = null
var can_shoot: bool = true

func _ready():
	super()
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	anim.frame_changed.connect(_on_frame_changed)

func _physics_process(delta):
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

func _shoot():
	can_shoot = false
	shoot_timer.start(1.5)
	anim.play("attack" if anim.sprite_frames.has_animation("attack") else "idle")

func _spawn_projectile():
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)

func _on_player_entered(body: Node2D):
	player_in_range = body
	if can_shoot:
		_shoot()

func _on_player_exited(body: Node2D):
	if body == player_in_range:
		player_in_range = null

func _on_shoot_timer_timeout():
	can_shoot = true

func _on_frame_changed():
	if anim.animation == "attack" and anim.frame == 6:
		_spawn_projectile()
