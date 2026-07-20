extends Node
class_name StartScreen

@export_file("*.tscn") var game_scene_path: String = "res://scenes/main.tscn"

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	if start_button != null:
		start_button.pressed.connect(_on_start_button_pressed)
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
