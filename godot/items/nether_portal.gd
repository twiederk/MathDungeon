class_name NetherPortal
extends Item


func execute() -> void:
	get_tree().change_scene_to_file("res://nether.tscn")
