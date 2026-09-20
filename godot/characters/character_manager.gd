extends Node

const DEFAULT_CHARACTER_ID: String = "000"
const SECOND_CHARACTER_ID: String = "001"
const THIRD_CHARACTER_ID: String = "002"

var current: Character


func _ready() -> void:
	_ensure_default_character(DEFAULT_CHARACTER_ID, "Steve")
	_ensure_default_character(SECOND_CHARACTER_ID, "Tobias")
	_ensure_default_character(THIRD_CHARACTER_ID, "Torsten")
	# selection screen (Phase 6) doesn't exist yet, so start with the default character
	if not SaveManager.load_and_activate_character(DEFAULT_CHARACTER_ID):
		current = Character.new()


func _ensure_default_character(id: String, display_name: String) -> void:
	if SaveManager.character_exists(id):
		return
	var character := Character.new()
	character.id = id
	character.display_name = display_name
	SaveManager.save_character(character)


func get_total_damage() -> int:
	return current.get_total_damage(self)



