class_name GoodResource
extends Resource

enum GoodType { OTHER, HEALING_POTION }

const LEVEL_ALL_DUNGEON_LEVELS: int = 0

@export var id: String = ""
@export var name: String = ""
@export var level: int = 1
@export var good_type: GoodType = GoodType.OTHER
@export var icon_atlas: AtlasTexture


func get_level() -> int:
	return level
