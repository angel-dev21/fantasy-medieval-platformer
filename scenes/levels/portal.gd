extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var next_level_path: String = ""

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	anim.play("default")

func _on_body_entered(body: Node2D) -> void:
	if Network.mode == "multi" and not multiplayer.is_server():
		return
	if triggered:
		return
	if not body.is_in_group("player"):
		return
	triggered = true
	if Network.mode == "multi":
		rpc("_go_to_next_level")
	call_deferred("_go_to_next_level")

@rpc("authority", "call_remote")
func _go_to_next_level() -> void:
	call_deferred("_do_change_scene")

func _do_change_scene() -> void:
	get_tree().change_scene_to_file(next_level_path)
