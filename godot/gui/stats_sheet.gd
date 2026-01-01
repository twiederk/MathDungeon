class_name StatsSheet
extends Control


@onready var health_meter_widget: HealthMeterWidget = $VBoxContainer/HealthMeterWidget
@onready var damage_label: Label = $VBoxContainer/DamageLabel
@onready var armor_label: Label = $VBoxContainer/ArmorLabel


func update_player_stats() -> void:
	health_meter_widget.update_health_ui(PlayerStats.hit_points)
	health_meter_widget.update_max_health_ui(PlayerStats.max_hit_points)
	damage_label.text = "Damage: " + str(PlayerStats.weapon_damage)
	armor_label.text = "Armor: " + str(PlayerStats.armor)


func update_enemy_stats(enemy: Enemy) -> void:
	health_meter_widget.update_health_ui(enemy.hit_points)
	health_meter_widget.update_max_health_ui(enemy.stats.max_hit_points)
	damage_label.text = "Damage: " + str(enemy.stats.damage)
	armor_label.text = "Armor: " + str(enemy.stats.armor)


func update_health_only(hit_points: int) -> void:
	health_meter_widget.update_health_ui(hit_points)