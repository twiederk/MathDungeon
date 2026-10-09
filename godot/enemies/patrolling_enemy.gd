class_name PatrollingEnemy
extends Path2D

signal encountered(enemy: StaticBody2D)

@export var patrol_speed: float = 50.0 
@export var location: String = ""

@onready var path_follow = $PathFollow2D
@onready var enemy = $PathFollow2D/Enemy


func _ready() -> void:
	path_follow.progress_ratio = randf_range(0, 1)
	enemy.location = location


func _process(delta: float) -> void:
	path_follow.progress += patrol_speed * delta
	if enemy == null or enemy.is_queued_for_deletion():
		queue_free()


func _on_enemy_encountered(a_enemy):
	encountered.emit(a_enemy)
