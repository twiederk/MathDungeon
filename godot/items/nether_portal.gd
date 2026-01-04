class_name NetherPortal
extends Item


func execute() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://nether.tscn")
