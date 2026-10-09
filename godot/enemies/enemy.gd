class_name Enemy
extends StaticBody2D


@export var stats: EnemyStats
@export var location: String = ""

signal encountered(enemy: StaticBody2D)
signal health_changed
signal defeated(enemy: Enemy)

@onready var detection_area: Area2D = $DetectionArea

@onready var hit_points: int = 5:
	set(value):
		hit_points = value
		health_changed.emit()


func _ready() -> void:
	hit_points = stats.get_max_hit_points()
	detection_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		encountered.emit(self)
		
		
func has_time_limit() -> bool:
	return stats.has_time_limit()


func hurt(damage: int) -> int:
	hit_points -= max(1, damage - stats.get_armor())
	if hit_points <= 0:
		defeated.emit(self)
	return hit_points
