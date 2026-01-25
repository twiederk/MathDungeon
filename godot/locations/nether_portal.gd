class_name NetherPortal
extends Node2D


@export var dungeon_path: String


var active: bool = false


@onready var inner_sprite_2d = $InnerSprite2D


func _on_outer_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if PlayerStats.has_lighter:
		active = true
		inner_sprite_2d.visible = true


func _on_inner_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if active:
		get_tree().call_deferred("change_scene_to_file", dungeon_path)
