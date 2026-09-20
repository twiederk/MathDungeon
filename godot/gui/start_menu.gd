class_name StartMenu
extends Control

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var load_button = $CenterContainer/VBoxContainer/LoadButton
@onready var character_widget: CharacterWidget = $CharacterWidget


func _ready():
	if not SaveManager.character_exists(CharacterManager.DEFAULT_CHARACTER_ID):
		load_button.set_disabled(true)
	start_button.grab_focus()


func _on_start_game_button_pressed():
	AchievementManager.reset()
	get_tree().change_scene_to_file("res://classic/main.tscn")


func _on_start_generic_button_pressed():
	AchievementManager.reset()
	get_tree().change_scene_to_file("res://procedural/proc_gen_world.tscn")


func _on_load_button_pressed():
	var target_id := CharacterManager.DEFAULT_CHARACTER_ID
	if CharacterManager.current.id == CharacterManager.DEFAULT_CHARACTER_ID:
		target_id = CharacterManager.SECOND_CHARACTER_ID
	elif CharacterManager.current.id == CharacterManager.SECOND_CHARACTER_ID:
		target_id = CharacterManager.THIRD_CHARACTER_ID
	else:
		target_id = CharacterManager.DEFAULT_CHARACTER_ID
	if SaveManager.load_and_activate_character(target_id):
		character_widget.update_stats()


func _on_highscores_button_pressed():
	get_tree().change_scene_to_file("res://gui/highscore_gui.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
