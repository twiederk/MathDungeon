class_name Enemy
extends Area2D

@export var stats: EnemyStats

signal encountered(enemy: Area2D)
signal health_changed

@onready var hit_points: int = 5:
	set(value):
		hit_points = value
		health_changed.emit()


func _ready() -> void:
	hit_points = stats.max_hit_points
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		encountered.emit(self)
		
		
func has_time_limit() -> bool:
	return stats.time_limit != -1
