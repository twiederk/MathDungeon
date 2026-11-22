class_name LevelConfig


var seed_value: int = 0
var size: Vector2i = Vector2i.ZERO
var splits: int = 0
var easy_enemies: Array[PackedScene] = []
var medium_enemies: Array[PackedScene] = []


func _init(level_seed: int = 0, level_size: Vector2i = Vector2i.ZERO, level_splits: int = 0) -> void:
	seed_value = level_seed
	size = level_size
	splits = level_splits


func duplicate() -> LevelConfig:
	var copy := LevelConfig.new(seed_value, size, splits)
	copy.easy_enemies.assign(easy_enemies)
	copy.medium_enemies.assign(medium_enemies)
	return copy