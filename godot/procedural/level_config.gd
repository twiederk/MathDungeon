class_name LevelConfig


var seed_value: int = 0
var size: Vector2i = Vector2i.ZERO
var splits: int = 0
var level: int = 1


func _init(level_seed: int = 0, level_size: Vector2i = Vector2i.ZERO, level_splits: int = 0, procedural_level: int = 1) -> void:
	seed_value = level_seed
	size = level_size
	splits = level_splits
	level = procedural_level


func duplicate() -> LevelConfig:
	return LevelConfig.new(seed_value, size, splits, level)