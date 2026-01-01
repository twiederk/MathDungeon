class_name StatsSheet
extends Control


@onready var health_meter_widget: HealthMeterWidget = $VBoxContainer/HealthMeterWidget
@onready var damage_label: Label = $VBoxContainer/DamageLabel
@onready var armor_label: Label = $VBoxContainer/ArmorLabel


func update_stats(hit_points: int, max_hit_points: int, damage: int, armor: int) -> void:
	health_meter_widget.update_health_ui(hit_points)
	health_meter_widget.update_max_health_ui(max_hit_points)
	damage_label.text = "Schaden: " + str(damage)
	armor_label.text = "Rüstung: " + str(armor)


func update_health_only(hit_points: int) -> void:
	health_meter_widget.update_health_ui(hit_points)
