class_name ProceduralStairs
extends Area2D


signal activated(goes_down: bool)

@export var goes_down: bool = false

@onready var spawn_point: Marker2D = $SpawnPoint


func get_spawn_point() -> Vector2:
	return spawn_point.global_position


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	activated.emit(goes_down)
