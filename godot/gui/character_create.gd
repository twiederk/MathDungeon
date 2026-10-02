class_name CharacterCreate
extends Control


const PORTRAIT_CATALOG: PortraitCatalog = preload("res://characters/portrait_catalog.tres")
const PORTRAIT_BUTTON_SCENE = preload("res://gui/portrait_button.tscn")
const MAX_NAME_LENGTH: int = 16
const MAX_CHARACTER_ID: int = 1000
const CHARACTER_ID_PADDING: int = 3

@onready var name_input: LineEdit = $VBoxContainer/NameContainer/NameInput
@onready var portrait_grid: GridContainer = $VBoxContainer/PortraitGrid
@onready var create_button: Button = $VBoxContainer/ButtonContainer/CreateButton
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton
@onready var error_label: Label = $VBoxContainer/ErrorLabel

var selected_portrait_id: String = CharacterManager.DEFAULT_CHARACTER_ID


func _ready() -> void:
	_setup_portrait_grid()
	name_input.grab_focus()


func _setup_portrait_grid() -> void:
	for child in portrait_grid.get_children():
		child.queue_free()
	
	for portrait in PORTRAIT_CATALOG.portraits:
		var portrait_button = PORTRAIT_BUTTON_SCENE.instantiate()
		portrait_grid.add_child(portrait_button)
		
		portrait_button.setup(portrait)
		portrait_button.portrait_selected.connect(_on_portrait_selected)
		
		if portrait.id == CharacterManager.DEFAULT_CHARACTER_ID:
			portrait_button.highlight()


func _on_portrait_selected(portrait_id: String) -> void:
	selected_portrait_id = portrait_id
	for button in portrait_grid.get_children():
		if button is Button:
			if button.get_meta("portrait_id") == portrait_id:
				button.highlight()
			else:
				button.unhighlight()


func _on_name_changed(_new_text: String) -> void:
	error_label.text = ""


func _on_create_pressed() -> void:
	var sanitized_name = _sanitize_name(name_input.text)
	
	var error = _validate_name(sanitized_name)
	if error:
		error_label.text = error
		return
	
	var character = _create_character(sanitized_name)
	SaveManager.save_character(character)
	
	CharacterManager.current = character
	get_tree().change_scene_to_file("res://gui/start_menu.tscn")


func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file("res://gui/start_menu.tscn")


func _create_character(character_name: String) -> Character:
	var character := Character.new()
	character.display_name = character_name
	character.portrait_id = selected_portrait_id
	character.max_hit_points = 5
	character.hit_points = 5
	character.weapon_damage = 1
	character.armor = 0
	character.companions = []
	character.id = _generate_unique_id()
	return character


func _sanitize_name(character_name: String) -> String:
	var trimmed = character_name.strip_edges()
	if trimmed.length() > MAX_NAME_LENGTH:
		trimmed = trimmed.substr(0, MAX_NAME_LENGTH)
	return trimmed


func _validate_name(character_name: String) -> String:
	if character_name.is_empty():
		return "Bitte einen Namen eingeben."
	return ""


func _generate_unique_id() -> String:
	var next_id = SaveManager.list_character_ids().size()
	
	while next_id < MAX_CHARACTER_ID:
		var id_string = str(next_id).pad_zeros(CHARACTER_ID_PADDING)
		if not SaveManager.character_exists(id_string):
			return id_string
		next_id += 1
	
	return str(MAX_CHARACTER_ID - 1).pad_zeros(CHARACTER_ID_PADDING)
