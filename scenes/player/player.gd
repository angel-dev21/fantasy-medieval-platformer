extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var is_attacking = false

func _ready():
	anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	if anim.animation == "attack":
		is_attacking = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_attacking:
		if Input.is_action_just_pressed("up") and is_on_floor():
			jump_sound.play()
			velocity.y = JUMP_VELOCITY

		var direction := Input.get_axis("left", "right")
		if direction > 0:
			anim.flip_h = false
		elif direction < 0:
			anim.flip_h = true

		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		anim.play("attack")
	elif not is_attacking:
		if not is_on_floor():
			anim.play("jump")
		elif velocity.x != 0:
			anim.play("run")
		else:
			anim.play("idle")

	move_and_slide()
