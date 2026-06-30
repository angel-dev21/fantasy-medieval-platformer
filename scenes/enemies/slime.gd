extends EnemyBase

@onready var detection_area: Area2D = $AnimatedSprite2D/DetectionArea
@onready var damage_area: Area2D = $DamageArea
@onready var damage_timer: Timer = $DamageTimer

var jump_force: float = -250.0
var jump_interval: float = 1.0
var jump_timer: float = 0.0
var is_jumping: bool = false
var players_touching: Array[Node2D] = []

func _ready() -> void:
	super()
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	damage_timer.start()

func _play_idle_animation() -> void:
	anim.play("default")

func _physics_process(delta: float) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		move_and_slide()
		return
	if health.is_dead():
		return
	var target := _get_target()
	if target:
		jump_timer -= delta
		if is_on_floor() and jump_timer <= 0:
			velocity.y = jump_force
			velocity.x = direction * speed
			jump_timer = jump_interval
			is_jumping = true
		elif is_jumping and is_on_floor():
			is_jumping = false
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
	super(delta)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if not players_touching.has(body):
		players_touching.append(body)
	_apply_contact_damage(body)

func _on_damage_area_body_exited(body: Node2D) -> void:
	players_touching.erase(body)

func _on_damage_timer_timeout() -> void:
	for p in players_touching:
		if is_instance_valid(p):
			_apply_contact_damage(p)

func _apply_contact_damage(body: Node2D) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	var target_health = body.get_node_or_null("Health")
	if target_health:
		target_health.take_damage(1)
