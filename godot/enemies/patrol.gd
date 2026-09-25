class_name Patrol
extends Path2D


@export var patrol_speed: float = 50.0 

@onready var path_follow = $PathFollow2D


func _process(delta: float) -> void:
	path_follow.progress += patrol_speed * delta
