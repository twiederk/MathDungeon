class_name ProceduralGameSession


const FIRST_PROCEDURAL_LEVEL := 1
const FIRST_PROCEDURAL_LEVEL_SIZE := Vector2i(40, 23)
const PROCEDURAL_LEVEL_SIZE_INCREMENT := Vector2i(20, 20)
const FIRST_PROCEDURAL_LEVEL_SPLITS := 3
const PROCEDURAL_LEVEL_SPLIT_INCREMENT := 1
const MAX_VECTOR2I_COMPONENT := 2_147_483_647
const NO_SEED := 0


var procedural_level_index: int = FIRST_PROCEDURAL_LEVEL
var procedural_level_configs: Dictionary[int, LevelConfig] = {}
var procedural_spawn_at_end: bool = false


func start_procedural_run() -> LevelConfig:
	reset_procedural_progression()
	return get_or_create_procedural_level_config(FIRST_PROCEDURAL_LEVEL)


func reset_procedural_progression() -> void:
	procedural_level_index = FIRST_PROCEDURAL_LEVEL
	procedural_level_configs.clear()
	procedural_spawn_at_end = false


func get_or_create_procedural_level_config(level_index: int) -> LevelConfig:
	if level_index < FIRST_PROCEDURAL_LEVEL:
		push_error("Procedural level index must be at least one.")
		return null
	if procedural_level_configs.has(level_index):
		return procedural_level_configs[level_index].duplicate()

	var growth_steps := level_index - FIRST_PROCEDURAL_LEVEL
	@warning_ignore("integer_division")
	var max_growth_steps_x := (MAX_VECTOR2I_COMPONENT - FIRST_PROCEDURAL_LEVEL_SIZE.x) / PROCEDURAL_LEVEL_SIZE_INCREMENT.x
	@warning_ignore("integer_division")
	var max_growth_steps_y := (MAX_VECTOR2I_COMPONENT - FIRST_PROCEDURAL_LEVEL_SIZE.y) / PROCEDURAL_LEVEL_SIZE_INCREMENT.y
	if growth_steps > min(max_growth_steps_x, max_growth_steps_y):
		push_error("Procedural level size exceeds Vector2i limits.")
		return null

	var level_seed := randi()
	while level_seed == NO_SEED:
		level_seed = randi()
	var level_size := FIRST_PROCEDURAL_LEVEL_SIZE + PROCEDURAL_LEVEL_SIZE_INCREMENT * growth_steps
	var level_splits := FIRST_PROCEDURAL_LEVEL_SPLITS + PROCEDURAL_LEVEL_SPLIT_INCREMENT * growth_steps
	var level_config := LevelConfig.new(level_seed, level_size, level_splits)
	procedural_level_configs[level_index] = level_config
	return level_config.duplicate()