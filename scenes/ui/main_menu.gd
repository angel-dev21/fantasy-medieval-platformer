extends Control

@onready var ip_input: LineEdit = $VBoxContainer/HBoxContainer/IPInput
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/HBoxContainer/JoinButton
@onready var solo_button: Button = $VBoxContainer/SoloButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

func _ready() -> void:
	Network.connected_to_game.connect(_on_connected)
	Network.connection_failed.connect(_on_failed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	solo_button.pressed.connect(_on_solo_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_solo_pressed() -> void:
	Network.mode = "solo"
	_load_game()

func _on_host_pressed() -> void:
	status_label.text = "Waiting for player..."
	Network.start_server()

func _on_join_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip == "":
		status_label.text = "Enter an IP"
		return
	status_label.text = "Connecting..."
	Network.start_client(ip)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_connected() -> void:
	_load_game()

func _on_failed() -> void:
	status_label.text = "Connection failed"

func _load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/first_level.tscn")
