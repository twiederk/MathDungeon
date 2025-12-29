class_name StartMenu
extends Control

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var load_button = $CenterContainer/VBoxContainer/LoadButton


func _ready():
	if not SaveManager.is_save_game_available():
		load_button.set_disabled(true)
	start_button.grab_focus()


func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


func _on_load_button_pressed():
	SaveManager.load_game()


func _on_quit_button_pressed():
	get_tree().quit()
