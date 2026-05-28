extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

const SPEED = 80.0
var direction = 1

func _ready():
	anim.play("default")
	timer.wait_time = 2.0
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	direction = -direction 
	anim.flip_h = direction < 0

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	velocity.x = direction * SPEED
	move_and_slide()
