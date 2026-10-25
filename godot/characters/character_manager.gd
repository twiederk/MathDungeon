extends Node


const DEFAULT_CHARACTER_ID: String = "000"
const DEFAULT_CHARACTER_NAME: String = "Steve"

signal eyes_of_ender_changed
signal has_lighter_changed


var current: Character:
	set(value):
		if current != null:
			current.eyes_of_ender_changed.disconnect(_on_eyes_of_ender_changed)
			current.has_lighter_changed.disconnect(_on_has_lighter_changed)
		current = value
		if current != null:
			current.eyes_of_ender_changed.connect(_on_eyes_of_ender_changed)
			current.has_lighter_changed.connect(_on_has_lighter_changed)


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


func _on_eyes_of_ender_changed() -> void:
	eyes_of_ender_changed.emit()


func _on_has_lighter_changed() -> void:
	has_lighter_changed.emit()
