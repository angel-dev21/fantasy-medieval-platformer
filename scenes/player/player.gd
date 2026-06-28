extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var sword_hit: Area2D
@onready var sword_collision: CollisionShape2D = $SwordHit/CollisionShape2D

const SPEED = 300.0
const JUMP_VELOCITY = -350.0

enum State { IDLE, RUN, JUMP, FALL, ATTACK }
var state: State = State.IDLE

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	sword_collision.disabled = true

func _on_animation_finished():
	if anim.animation == "attack":
		sword_collision.disabled = true
		change_state(State.IDLE)

func change_state(new_state: State) -> void:
	state = new_state
	match state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
		State.JUMP:
			anim.play("jump")
		State.FALL:
			anim.play("fall")
		State.ATTACK:
			anim.play("attack")
			sword_collision.disabled = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if state != State.ATTACK:
		if Input.is_action_just_pressed("up") and is_on_floor():
			jump_sound.play()
			velocity.y = JUMP_VELOCITY
			change_state(State.JUMP)

		var direction := Input.get_axis("left", "right")
		if direction > 0:
			anim.flip_h = false
			sword_hit.scale.x = 1
		elif direction < 0:
			anim.flip_h = true
			sword_hit.scale.x = -1

		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		if Input.is_action_just_pressed("attack"):
			change_state(State.ATTACK)
		else:
			_update_movement_state()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _update_movement_state() -> void:
	if not is_on_floor():
		if velocity.y < 0:
			change_state(State.JUMP)
		elif velocity.y > 0 and state != State.FALL:
			change_state(State.FALL)
	elif velocity.x != 0:
		if state != State.RUN:
			change_state(State.RUN)
	else:
		if state != State.IDLE:
			change_state(State.IDLE)

func _on_sword_hit_body_entered(body: Node2D) -> void:
	if body is EnemyBase:
		body.take_damage(1)
