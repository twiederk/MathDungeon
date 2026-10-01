class_name StartMenu
extends Control

const DIFFICULTY_LABELS := {
	GameSession.DifficultyLevel.NORMAL: "Schwierigkeitsgrad: normal",
	GameSession.DifficultyLevel.HARD: "Schwierigkeitsgrad: schwer"
}

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var load_button = $CenterContainer/VBoxContainer/LoadButton
@onready var difficulty_button: Button = $CenterContainer/VBoxContainer/DifficultyButton
@onready var character_widget: CharacterWidget = $CharacterWidget


func _ready():
	SaveManager.load_and_activate_character(CharacterManager.current.id)
	character_widget.update_stats()
	_update_difficulty_button()
	start_button.grab_focus()


func _on_difficulty_button_pressed() -> void:
	GameSession.toggle_difficulty_level()
	_update_difficulty_button()


func _update_difficulty_button() -> void:
	difficulty_button.text = DIFFICULTY_LABELS[GameSession.difficulty_level]


func _on_start_game_button_pressed():
	GameSession.reset()
	AchievementManager.reset()
	get_tree().change_scene_to_file("res://classic/main.tscn")


func _on_start_generic_button_pressed():
	GameSession.reset()
	AchievementManager.reset()
	get_tree().change_scene_to_file("res://procedural/proc_gen_world.tscn")


func _on_load_button_pressed():
	var target_id = CharacterManager.DEFAULT_CHARACTER_ID
	if CharacterManager.current.id == CharacterManager.DEFAULT_CHARACTER_ID:
		target_id = CharacterManager.SECOND_CHARACTER_ID
	elif CharacterManager.current.id == CharacterManager.SECOND_CHARACTER_ID:
		target_id = CharacterManager.THIRD_CHARACTER_ID
	else:
		target_id = CharacterManager.DEFAULT_CHARACTER_ID
	SaveManager.load_and_activate_character(target_id)
	character_widget.update_stats()


func _on_new_character_button_pressed():
	get_tree().change_scene_to_file("res://gui/character_create.tscn")


func _on_highscores_button_pressed():
	get_tree().change_scene_to_file("res://gui/highscore_gui.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
