class_name Patrol
extends Path2D

signal encountered(enemy: StaticBody2D)

@export var patrol_speed: float = 50.0 

@onready var path_follow = $PathFollow2D
@onready var vindicator = $PathFollow2D/Vindicator

# The vindicator must signal his encoutered to Patrol!!!


func _process(delta: float) -> void:
	path_follow.progress += patrol_speed * delta


func _on_enemy_encountered(body: Node) -> void:
	vindicator._on_body_entered(body)


func _on_vindicator_encountered(enemy):
	encountered.emit(enemy)
