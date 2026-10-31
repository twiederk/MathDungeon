class_name NetherPortal
extends Node2D


@export var dungeon_path: String


var active: bool = false


@onready var inner_sprite_2d = $InnerSprite2D
@onready var spawn_point: Marker2D = $SpawnPoint


func get_spawn_position() -> Vector2:
	return spawn_point.global_position


func get_target_path() -> String:
	if dungeon_path.is_empty():
		return GameSession.overworld_path
	return dungeon_path


func _on_outer_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if CharacterManager.current.has_lighter():
		active = true
		inner_sprite_2d.visible = true


func _on_inner_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if active:
		GameSession.spawn_point = GameSession.SpawnPoint.NETHER_PORTAL
		get_tree().call_deferred("change_scene_to_file", get_target_path())
