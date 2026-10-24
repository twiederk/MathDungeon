class_name CharacterSheetGui
extends Control

@onready var health_meter_widget: HealthMeterWidget = $PanelContainer/MarginContainer/VBoxContainer/HealthMeterWidget
@onready var damage_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DamageLabel
@onready var armor_points_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ArmorPointsLabel
@onready var weapon_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WeaponLabel
@onready var armor_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ArmorLabel
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
	health_meter_widget.update_health_ui(character.hit_points)
	health_meter_widget.update_max_health_ui(character.max_hit_points)
	damage_label.text = "Schaden: " + str(character.get_total_damage())
	armor_points_label.text = "Rüstung: " + str(character.armor)
	weapon_label.text = "Waffe: " + _item_label(inventory.weapon_item_id, inventory.weapon_damage)
	armor_label.text = "Rüstung: " + _item_label(inventory.armor_item_id, inventory.armor_value)
	potion_label.text = "Tränke: %d/%d" % [inventory.potion_count, Inventory.MAX_POTIONS]
	lighter_label.text = "Feuerzeug: " + _yes_no(GameSession.has_lighter)
	eyes_of_ender_label.text = "Enderaugen: %d" % GameSession.eyes_of_ender


func _item_label(item_id: String, value: int) -> String:
	if item_id.is_empty():
		return "-"
	return "%s (%d)" % [item_id, value]


func _yes_no(value: bool) -> String:
	if value:
		return "Ja"
	return "Nein"
