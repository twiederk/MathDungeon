class_name GoodResource
extends ItemResource

enum GoodType { OTHER, HEALING_POTION }

const LEVEL_ALL_DUNGEON_LEVELS: int = 0

@export var level: int = 1
@export var good_type: GoodType = GoodType.OTHER


func get_level() -> int:
	return level
