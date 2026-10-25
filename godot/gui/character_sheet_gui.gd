class_name CharacterSheetGui
extends Control

const COMPANION_SPRITE_SHEET: Texture2D = preload("res://enemies/creatures.png")
const COMPANION_SPRITE_GRID_SIZE: int = 9
const COMPANION_SPRITE_FRAMES := {
	"Wolf": 7,
	"Allay": 63,
}

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var health_meter_widget: HealthMeterWidget = $PanelContainer/MarginContainer/VBoxContainer/HealthMeterWidget
@onready var damage_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DamageLabel
@onready var armor_points_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ArmorPointsLabel
@onready var weapon_row: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/WeaponRow
@onready var weapon_icon: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/WeaponRow/WeaponIcon
@onready var weapon_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WeaponRow/WeaponLabel
@onready var armor_row: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ArmorRow
@onready var armor_icon: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/ArmorRow/ArmorIcon
@onready var armor_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ArmorRow/ArmorLabel
@onready var potion_row: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/PotionRow
@onready var potion_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PotionRow/PotionLabel
@onready var lighter_row: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/LighterRow
@onready var lighter_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LighterRow/LighterLabel
@onready var eyes_of_ender_row: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/EyesOfEnderRow
@onready var eyes_of_ender_label: Label = $PanelContainer/MarginContainer/VBoxContainer/EyesOfEnderRow/EyesOfEnderLabel
@onready var companion_row: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/CompanionRow
@onready var companion_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CompanionRow/CompanionLabel


func _ready() -> void:
	GameSession.display_state_changed.connect(_on_display_state_changed)
	_on_display_state_changed(GameSession.display_state)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("character_sheet"):
		match GameSession.display_state:
			GameSession.DisplayState.NONE:
				GameSession.display_state = GameSession.DisplayState.CHARACTER_SHEET
			GameSession.DisplayState.CHARACTER_SHEET:
				GameSession.display_state = GameSession.DisplayState.NONE
			GameSession.DisplayState.QUEST_LOG:
				GameSession.display_state = GameSession.DisplayState.CHARACTER_SHEET


func _on_display_state_changed(state: int) -> void:
	if state == GameSession.DisplayState.CHARACTER_SHEET:
		_show_menu()
	else:
		_hide_menu()


func _show_menu() -> void:
	_refresh()
	visible = true


func _hide_menu() -> void:
	visible = false


func _refresh() -> void:
	var character := CharacterManager.current
	var inventory := character.inventory
	title_label.text = character.display_name
	health_meter_widget.update_health_ui(character.hit_points)
	health_meter_widget.update_max_health_ui(character.max_hit_points)
	damage_label.text = "Schaden: " + str(character.get_damage())
	armor_points_label.text = "Rüstung: " + str(character.get_armor())
	_update_item_row(weapon_row, weapon_icon, weapon_label, inventory.weapon_resource, inventory.get_weapon_name(), inventory.get_weapon_damage())
	_update_item_row(armor_row, armor_icon, armor_label, inventory.armor_resource, inventory.get_armor_name(), inventory.get_armor_value())
	potion_label.text = "Tränke (max. %d):" % Inventory.MAX_POTIONS
	_update_good_icons(potion_row, potion_label, inventory, Inventory.HEALING_POTION_ID)
	lighter_label.text = "Feuerzeug:"
	_update_good_icons(lighter_row, lighter_label, inventory, Character.LIGHTER_ID)
	eyes_of_ender_label.text = "Enderaugen:"
	_update_good_icons(eyes_of_ender_row, eyes_of_ender_label, inventory, Character.EYE_OF_ENDER_ID)
	companion_label.text = "Begleiter:"
	_update_companion_icons(character)


func _item_label(item_name: String, value: int) -> String:
	if item_name.is_empty():
		return "-"
	return "%s (%d)" % [item_name, value]


func _update_item_row(row: HBoxContainer, icon_rect: TextureRect, label: Label, resource, item_name: String, value: int) -> void:
	if resource == null:
		row.visible = false
		return
	icon_rect.texture = resource.get_icon()
	label.text = _item_label(item_name, value)
	row.visible = true


func _update_good_icons(row: HBoxContainer, label: Label, inventory: Inventory, good_id: String) -> void:
	_clear_good_icons(row, label)
	_add_good_icons(row, inventory, good_id)


func _clear_good_icons(row: HBoxContainer, label: Label) -> void:
	for child in row.get_children():
		if child != label:
			child.queue_free()
			row.remove_child(child)


func _add_good_icons(row: HBoxContainer, inventory: Inventory, good_id: String) -> void:
	for good in inventory.goods:
		if good.id != good_id:
			continue
		row.add_child(_create_icon_rect(good.get_icon()))


func _update_companion_icons(character: Character) -> void:
	_clear_good_icons(companion_row, companion_label)
	for companion_type in character.companions:
		if not COMPANION_SPRITE_FRAMES.has(companion_type):
			continue
		companion_row.add_child(_create_icon_rect(_companion_icon(companion_type)))


func _companion_icon(companion_type: String) -> Texture2D:
	var frame: int = COMPANION_SPRITE_FRAMES[companion_type]
	var atlas := AtlasTexture.new()
	atlas.atlas = COMPANION_SPRITE_SHEET
	var cell := COMPANION_SPRITE_SHEET.get_size() / Vector2(COMPANION_SPRITE_GRID_SIZE, COMPANION_SPRITE_GRID_SIZE)
	var col := frame % COMPANION_SPRITE_GRID_SIZE
	@warning_ignore("integer_division")
	var row := frame / COMPANION_SPRITE_GRID_SIZE
	atlas.region = Rect2(col * cell.x, row * cell.y, cell.x, cell.y)
	return atlas


func _create_icon_rect(texture: Texture2D) -> TextureRect:
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(20, 20)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = texture
	return icon_rect
