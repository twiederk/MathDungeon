class_name CaveEntrance
extends Node2D


@export var dungeon_path: String

@onready var spawn_point: Marker2D = $SpawnPoint


func get_spawn_position() -> Vector2:
	return spawn_point.global_position


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	GameSession.spawn_point = GameSession.SpawnPoint.CAVE_ENTRANCE
	get_tree().call_deferred("change_scene_to_file", dungeon_path)
