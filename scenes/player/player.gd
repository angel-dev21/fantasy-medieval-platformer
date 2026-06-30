extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var camera: Camera2D = $Camera2D
@onready var sword_hit: Area2D = $SwordHit
@onready var sword_collision: CollisionShape2D = $SwordHit/CollisionShape2D
@onready var health: Node = $Health

const speed: float = 300.0
const jump_velocity: float = -350.0

enum State { IDLE, RUN, JUMP, FALL, ATTACK, DEAD, HURT }
var state: State = State.IDLE
var alive_collision_layer: int

func _enter_tree() -> void:
	var id = name.to_int()
	if id > 0:
		set_multiplayer_authority(id)

func _ready() -> void:
	alive_collision_layer = collision_layer
	sword_hit.body_entered.connect(_on_sword_hit_body_entered)
	anim.animation_finished.connect(_on_animation_finished)
	health.died.connect(_on_died, CONNECT_ONE_SHOT)
	health.health_changed.connect(_on_health_changed)
	camera.enabled = is_multiplayer_authority()
	change_state(State.IDLE)

func _on_animation_finished() -> void:
	if anim.animation == "attack" or anim.animation == "hurt":
		change_state(State.IDLE)

func change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	sword_collision.disabled = true
	match new_state:
		State.IDLE:   anim.play("idle")
		State.RUN:    anim.play("run")
		State.JUMP:   anim.play("jump")
		State.FALL:   anim.play("fall")
		State.ATTACK:
			anim.play("attack")
			sword_collision.disabled = false
		State.DEAD:
			anim.play("death")
		State.HURT:
			anim.play("hurt")

func _set_direction(dir: float) -> void:
	anim.flip_h = dir < 0
	sword_hit.scale.x = sign(dir)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		move_and_slide()
		return
	if state == State.DEAD or state == State.HURT:
		velocity.x = 0
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if state != State.ATTACK:
		if Input.is_action_just_pressed("up") and is_on_floor():
			jump_sound.play()
			velocity.y = jump_velocity
			change_state(State.JUMP)
		var direction := Input.get_axis("left", "right")
		if direction != 0:
			_set_direction(direction)
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
		if Input.is_action_just_pressed("attack"):
			change_state(State.ATTACK)
		else:
			_update_movement_state()
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()

func _update_movement_state() -> void:
	if not is_on_floor():
		if velocity.y < 0:
			change_state(State.JUMP)
		elif velocity.y > 0:
			change_state(State.FALL)
	elif velocity.x != 0:
		change_state(State.RUN)
	else:
		change_state(State.IDLE)

func _on_sword_hit_body_entered(body: Node2D) -> void:
	if not is_multiplayer_authority():
		return
	if body is EnemyBase:
		body.get_node("Health").take_damage(1)

func _on_health_changed(current: int, max: int) -> void:
	if current > 0:
		call_deferred("change_state", State.HURT)

func _on_died() -> void:
	call_deferred("change_state", State.DEAD)
	set_deferred("collision_layer", 0)

func revive(spawn_position: Vector2) -> void:
	global_position = spawn_position
	set_deferred("collision_layer", alive_collision_layer)
	health.current_health = health.max_health
	health.health_changed.emit(health.current_health, health.max_health)
	if not health.died.is_connected(_on_died):
		health.died.connect(_on_died, CONNECT_ONE_SHOT)
	_on_revived()

func _on_revived() -> void:
	change_state(State.IDLE)
