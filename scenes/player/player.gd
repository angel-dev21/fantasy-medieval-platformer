extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var sword_hit: Area2D = $SwordHit
@onready var sword_collision: CollisionShape2D = $SwordHit/CollisionShape2D
@onready var health: Node = $Health

const speed: float = 300.0
const jump_velocity: float = -350.0

enum State { IDLE, RUN, JUMP, FALL, ATTACK, DEAD, HURT }
var state: State = State.IDLE
var alive_collision_layer: int
var spectating_target: Node2D = null

func _enter_tree() -> void:
	var id = name.to_int()
	if id > 0:
		set_multiplayer_authority(id)

func _ready() -> void:
	add_to_group("player")
	alive_collision_layer = collision_layer
	sword_hit.body_entered.connect(_on_sword_hit_body_entered)
	anim.animation_finished.connect(_on_animation_finished)
	health.died.connect(_on_died, CONNECT_ONE_SHOT)
	health.damaged.connect(_on_damaged)
	health.revived.connect(_on_revived)
	camera.enabled = is_multiplayer_authority()
	change_state(State.IDLE)

func _on_animation_finished() -> void:
	if anim.animation == "attack" or anim.animation == "hurt":
		change_state(State.IDLE)

func change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	sword_collision.set_deferred("disabled", true)
	match new_state:
		State.IDLE:   anim.play("idle")
		State.RUN:    anim.play("run")
		State.JUMP:   anim.play("jump")
		State.FALL:   anim.play("fall")
		State.ATTACK:
			anim.play("attack")
			sword_collision.set_deferred("disabled", false)
		State.DEAD:
			anim.play("death")
		State.HURT:
			anim.play("hurt")

func _set_direction(dir: float) -> void:
	anim.flip_h = dir < 0
	sword_hit.scale.x = sign(dir)

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if state == State.DEAD:
		if spectating_target and is_instance_valid(spectating_target):
			var target_health = spectating_target.get_node_or_null("Health")
			if target_health and target_health.is_dead():
				spectating_target = null
			else:
				camera.global_position = spectating_target.global_position
				return
		camera.position = Vector2.ZERO
	else:
		camera.position = Vector2.ZERO

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

func _on_damaged() -> void:
	call_deferred("change_state", State.HURT)

func _on_died() -> void:
	call_deferred("change_state", State.DEAD)
	set_deferred("collision_layer", 0)
	if is_multiplayer_authority():
		spectating_target = _find_other_alive_player()

func _find_other_alive_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p == self:
			continue
		var h = p.get_node_or_null("Health")
		if h and not h.is_dead():
			return p
	return null

func revive(spawn_position: Vector2) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	_apply_revive_position(spawn_position)
	if Network.mode == "multi":
		rpc("_apply_revive_position", spawn_position)
	health.revive()

@rpc("any_peer", "call_remote")
func _apply_revive_position(spawn_position: Vector2) -> void:
	global_position = spawn_position
	set_deferred("collision_layer", alive_collision_layer)

func _on_revived() -> void:
	if not health.died.is_connected(_on_died):
		health.died.connect(_on_died, CONNECT_ONE_SHOT)
	spectating_target = null
	change_state(State.IDLE)
