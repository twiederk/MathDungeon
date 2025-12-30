class_name HealthMeterWidget
extends Control


@onready var empty = $Empty
@onready var full = $Full


func update_health_ui(hit_points):
	full.size.x = hit_points * 10 + 2


func update_max_health_ui(max_hit_points):
	empty.size.x = max_hit_points * 10 + 2
	
