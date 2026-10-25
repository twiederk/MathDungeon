class_name CharacterSheetGui
extends Control

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
@onready var potion_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PotionLabel
@onready var lighter_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LighterLabel
@onready var eyes_of_ender_label: Label = $PanelContainer/MarginContainer/VBoxContainer/EyesOfEnderLabel


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
	potion_label.text = "Tränke: %d/%d" % [inventory.get_potion_count(), Inventory.MAX_POTIONS]
	lighter_label.text = "Feuerzeug: " + _yes_no(character.has_lighter)
	eyes_of_ender_label.text = "Enderaugen: %d" % character.get_eyes_of_ender_count()


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


func _yes_no(value: bool) -> String:
	if value:
		return "Ja"
	return "Nein"
