class_name EndPortal
extends Node2D

const REQUIRED_EYES_OF_ENDER: int = 12

@export var dungeon_path: String


var active: bool = false


@onready var inner_sprite_2d = $InnerSprite2D


func _on_outer_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if PlayerStats.eyes_of_ender >= REQUIRED_EYES_OF_ENDER:
		active = true
		inner_sprite_2d.visible = true


func _on_inner_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if active:
		get_tree().call_deferred("change_scene_to_file", dungeon_path)
