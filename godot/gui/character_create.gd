class_name CharacterCreate
extends Control


const PORTRAIT_CATALOG: PortraitCatalog = preload("res://characters/portrait_catalog.tres")
const MAX_NAME_LENGTH: int = 16

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
		var button := Button.new()
		button.custom_minimum_size = Vector2(64, 64)
		button.modulate = Color.WHITE
		
		var texture_rect := TextureRect.new()
		texture_rect.texture = portrait.texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.anchor_left = 0.0
		texture_rect.anchor_top = 0.0
		texture_rect.anchor_right = 1.0
		texture_rect.anchor_bottom = 1.0
		button.add_child(texture_rect)
		
		button.set_meta("portrait_id", portrait.id)
		button.pressed.connect(_on_portrait_selected.bindv([portrait.id]))
		
		portrait_grid.add_child(button)
		
		if portrait.id == CharacterManager.DEFAULT_CHARACTER_ID:
			_highlight_portrait_button(button)


func _highlight_portrait_button(button: Button) -> void:
	for child in portrait_grid.get_children():
		if child is Button:
			child.modulate = Color.WHITE

	button.modulate = Color.YELLOW


func _on_portrait_selected(portrait_id: String) -> void:
	selected_portrait_id = portrait_id
	var button = portrait_grid.get_children().filter(func(b): return b.get_meta("portrait_id") == portrait_id)[0]
	_highlight_portrait_button(button)


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
	
	# Set as current character and return to start menu
	CharacterManager.current = character
	get_tree().change_scene_to_file("res://gui/start_menu.tscn")


func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file("res://gui/start_menu.tscn")


func _create_character(character_name: String) -> Character:
	var character := Character.new()
	character.id = _generate_unique_id()
	character.display_name = character_name
	character.portrait_id = selected_portrait_id
	character.max_hit_points = 5
	character.hit_points = 5
	character.weapon_damage = 1
	character.armor = 0
	character.companions = []
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
	# Generate a unique ID based on timestamp and random number
	var timestamp = int(Time.get_ticks_msec())
	var random_part = randi() % 10000
	var id = str(timestamp % 1000000) + "_" + str(random_part)
	
	# Ensure ID is unique (retry if needed)
	var attempts = 0
	while SaveManager.character_exists(id) and attempts < 10:
		random_part = randi() % 10000
		id = str(timestamp % 1000000) + "_" + str(random_part)
		attempts += 1
	
	return id
