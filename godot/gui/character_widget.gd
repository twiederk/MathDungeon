class_name CharacterWidget
extends Control


@onready var name_label = $VBoxContainer/NameLabel
@onready var health_meter_widget: HealthMeterWidget = $VBoxContainer/HealthMeterWidget
@onready var damage_label: Label = $VBoxContainer/DamageLabel
@onready var armor_label: Label = $VBoxContainer/ArmorLabel
@onready var companion_label = $VBoxContainer/CompanionLabel


func _ready() -> void:
	update_stats()

func update_stats() -> void:
	var display_name  = CharacterManager.current.display_name
	var hit_points = CharacterManager.current.hit_points
	var max_hit_points = CharacterManager.current.max_hit_points
	var damage = CharacterManager.get_total_damage()
	var armor = CharacterManager.current.armor
	var number_of_companions = CharacterManager.current.companions.size()

	name_label.text = "Name: " + display_name
	health_meter_widget.update_health_ui(hit_points)
	health_meter_widget.update_max_health_ui(max_hit_points)
	damage_label.text = "Schaden: " + str(damage)
	armor_label.text = "Rüstung: " + str(armor)
	companion_label.text = "Wölfe: " + str(number_of_companions)
