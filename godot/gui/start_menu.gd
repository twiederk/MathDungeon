class_name StartMenu
extends Control

const DIFFICULTY_LABELS := {
	GameSession.DifficultyLevel.NORMAL: "Schwierigkeitsgrad: normal",
	GameSession.DifficultyLevel.HARD: "Schwierigkeitsgrad: schwer"
}

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var switch_character_button = $CenterContainer/VBoxContainer/SwitchCharacterButton
@onready var difficulty_button: Button = $CenterContainer/VBoxContainer/DifficultyButton
@onready var character_widget: CharacterWidget = $CharacterWidget


func _ready():
	SaveManager.load_and_activate_character(CharacterManager.current.id)
	_heal_current_character()
	character_widget.update_stats()
	_update_difficulty_button()
	start_button.grab_focus()


func _heal_current_character() -> void:
	CharacterManager.current.hit_points = CharacterManager.current.max_hit_points


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


func _on_switch_character_button_pressed():
	var characters = SaveManager.list_character_ids()
	if characters.is_empty():
		return
	
	var current_id = CharacterManager.current.id
	var current_index = characters.find(current_id)
	
	var next_index = (current_index + 1) % characters.size()
	var next_character_id = characters[next_index]
	
	SaveManager.load_and_activate_character(next_character_id)
	_heal_current_character()
	character_widget.update_stats()


func _on_new_character_button_pressed():
	get_tree().change_scene_to_file("res://gui/character_create_dialog.tscn")


func _on_highscores_button_pressed():
	get_tree().change_scene_to_file("res://gui/highscore_gui.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
