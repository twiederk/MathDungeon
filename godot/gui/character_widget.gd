class_name CharacterWidget
extends Control


@onready var stats_sheet: StatsSheet = $StatsSheet


func _ready() -> void:
	update_stats()


func update_stats() -> void:
	stats_sheet.update_stats(PlayerStats.hit_points, PlayerStats.max_hit_points, PlayerStats.get_total_damage(), PlayerStats.armor)
