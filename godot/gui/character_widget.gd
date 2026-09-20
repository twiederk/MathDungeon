class_name CharacterWidget
extends Control


@onready var health_meter_widget: HealthMeterWidget = $VBoxContainer/HealthMeterWidget
@onready var damage_label: Label = $VBoxContainer/DamageLabel
@onready var armor_label: Label = $VBoxContainer/ArmorLabel
@onready var companion_label = $VBoxContainer/CompanionLabel


func _ready() -> void:
	update_stats()

func update_stats() -> void:
	var hit_points = PlayerStats.hit_points
	var max_hit_points = PlayerStats.max_hit_points
	var damage = PlayerStats.get_total_damage()
	var armor = PlayerStats.armor
	var number_of_companions = PlayerStats.companion_paths.size()

	health_meter_widget.update_health_ui(hit_points)
	health_meter_widget.update_max_health_ui(max_hit_points)
	damage_label.text = "Schaden: " + str(damage)
	armor_label.text = "Rüstung: " + str(armor)
	companion_label.text = "Wölfe: " + str(number_of_companions)
