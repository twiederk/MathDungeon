class_name ProceduralGameSession


const FIRST_PROCEDURAL_LEVEL := 1
const FIRST_PROCEDURAL_LEVEL_SIZE := Vector2i(39, 22)
const PROCEDURAL_LEVEL_SIZE_INCREMENT := Vector2i(5, 5)
const PROCEDURAL_LEVEL_GROWTH_INTERVAL := 2
const MAX_PROCEDURAL_LEVEL_SIZE := Vector2i(120, 120)
const FIRST_PROCEDURAL_LEVEL_SPLITS := 3
const PROCEDURAL_LEVEL_SPLIT_THRESHOLDS := [
	{"size": Vector2i(60, 40), "splits": 4},
	{"size": Vector2i(100, 80), "splits": 5}
]
const PROCEDURAL_CLEAR_BONUSES := {3: 500, 4: 1000, 5: 2000}
const NO_SEED := 0


var procedural_level: int = FIRST_PROCEDURAL_LEVEL
var procedural_level_configs: Dictionary[int, LevelConfig] = {}
var procedural_spawn_at_end: bool = false


func start_procedural_run() -> LevelConfig:
	reset_procedural_progression()
	return get_or_create_procedural_level_config(FIRST_PROCEDURAL_LEVEL)


func reset_procedural_progression() -> void:
	procedural_level = FIRST_PROCEDURAL_LEVEL
	procedural_level_configs.clear()
	procedural_spawn_at_end = false


func get_or_create_procedural_level_config(level_index: int) -> LevelConfig:
	if level_index < FIRST_PROCEDURAL_LEVEL:
		push_error("Procedural level index must be at least one.")
		return null
	if procedural_level_configs.has(level_index):
		return procedural_level_configs[level_index].duplicate()

	@warning_ignore("integer_division")
	var growth_steps := (level_index - FIRST_PROCEDURAL_LEVEL) / PROCEDURAL_LEVEL_GROWTH_INTERVAL
	var max_growth_steps_x := ceili(float(MAX_PROCEDURAL_LEVEL_SIZE.x - FIRST_PROCEDURAL_LEVEL_SIZE.x) / PROCEDURAL_LEVEL_SIZE_INCREMENT.x)
	var max_growth_steps_y := ceili(float(MAX_PROCEDURAL_LEVEL_SIZE.y - FIRST_PROCEDURAL_LEVEL_SIZE.y) / PROCEDURAL_LEVEL_SIZE_INCREMENT.y)
	var level_size := Vector2i(
		mini(MAX_PROCEDURAL_LEVEL_SIZE.x, FIRST_PROCEDURAL_LEVEL_SIZE.x + PROCEDURAL_LEVEL_SIZE_INCREMENT.x * mini(growth_steps, max_growth_steps_x)),
		mini(MAX_PROCEDURAL_LEVEL_SIZE.y, FIRST_PROCEDURAL_LEVEL_SIZE.y + PROCEDURAL_LEVEL_SIZE_INCREMENT.y * mini(growth_steps, max_growth_steps_y))
	)

	var level_seed := randi()
	while level_seed == NO_SEED:
		level_seed = randi()
	var level_splits := _get_splits_for_size(level_size)
	var level_config := LevelConfig.new(level_seed, level_size, level_splits, level_index)
	procedural_level_configs[level_index] = level_config
	return level_config.duplicate()


func get_procedural_clear_bonus(splits: int) -> int:
	return PROCEDURAL_CLEAR_BONUSES[clampi(splits, 3, 5)]


func _get_splits_for_size(level_size: Vector2i) -> int:
	var splits := FIRST_PROCEDURAL_LEVEL_SPLITS
	for threshold in PROCEDURAL_LEVEL_SPLIT_THRESHOLDS:
		if level_size.x >= threshold.size.x and level_size.y >= threshold.size.y:
			splits = threshold.splits
	return splits
