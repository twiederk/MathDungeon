extends Node

const DEFAULT_CHARACTER_ID: String = "000"
const DEFAULT_CHARACTER_NAME: String = "Steve"

var current: Character


func _ready() -> void:
	_ensure_default_character()
	SaveManager.load_and_activate_character(DEFAULT_CHARACTER_ID)


func _ensure_default_character() -> void:
	if SaveManager.character_exists(DEFAULT_CHARACTER_ID):
		return
	var character := Character.new()
	character.id = DEFAULT_CHARACTER_ID
	character.display_name = DEFAULT_CHARACTER_NAME
	character.portrait_id = DEFAULT_CHARACTER_ID
	SaveManager.save_character(character)
