class_name NetherPortal
extends Item


@export var dungeon_path: String


func execute() -> void:
	get_tree().call_deferred("change_scene_to_file", dungeon_path)
