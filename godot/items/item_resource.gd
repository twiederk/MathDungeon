class_name ItemResource
extends Resource

const INVALID_LEVEL: int = -1

@export var id: String = ""
@export var name: String = ""
@export var icon_atlas: AtlasTexture


func get_level() -> int:
	return INVALID_LEVEL
