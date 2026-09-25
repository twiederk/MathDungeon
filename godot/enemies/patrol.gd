class_name Patrol
extends Path2D

signal encountered(enemy: StaticBody2D)

@export var patrol_speed: float = 50.0 

@onready var path_follow = $PathFollow2D
@onready var vindicator = $PathFollow2D/Vindicator


func _ready() -> void:
	path_follow.progress_ratio = randf_range(0, 1)


func _process(delta: float) -> void:
	path_follow.progress += patrol_speed * delta
	if vindicator == null or vindicator.is_queued_for_deletion():
		queue_free()


func _on_enemy_encountered(body: Node) -> void:
	vindicator._on_body_entered(body)


func _on_vindicator_encountered(enemy):
	encountered.emit(enemy)
