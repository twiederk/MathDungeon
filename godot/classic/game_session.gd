extends Node


enum DifficultyLevel {
	NORMAL,
	HARD
}

enum DisplayState {
	NONE,
	QUIZ_DIALOG,
	PAUSE_MENU,
	QUEST_LOG,
	CHARACTER_SHEET
}

enum SpawnPoint {
	START,
	NETHER_PORTAL,
	CAVE_ENTRANCE
}

enum GameMode {
	NORMAL,
	TIMED_RUN
}

const DEFAULT_OVERWORLD_PATH := "res://classic/overworld.tscn"
const NO_SEED := 0
const RUN_DURATION_SECONDS := 600.0
const FIRST_PROCEDURAL_LEVEL := 1
const FIRST_PROCEDURAL_LEVEL_SIZE := Vector2i(20, 20)
const PROCEDURAL_LEVEL_SIZE_INCREMENT := Vector2i(20, 20)
const MAX_VECTOR2I_COMPONENT := 2_147_483_647


signal score_changed
signal display_state_changed(state: int)
signal simulation_running_changed(running: bool)
signal highscore_rank_changed(rank: int)
signal run_time_changed(seconds_left: float)
signal run_time_expired


var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL
var spawn_point: SpawnPoint = SpawnPoint.START
var overworld_path: String = DEFAULT_OVERWORLD_PATH
var world_seed: int = NO_SEED
var procedural_level_index: int = FIRST_PROCEDURAL_LEVEL
var procedural_level_configs: Dictionary = {}
var procedural_spawn_at_end: bool = false
var highscore_rank: int = HighscoreManager.NO_RANK
var game_mode: GameMode = GameMode.NORMAL
var run_duration_seconds: float = RUN_DURATION_SECONDS
var run_time_left: float = 0.0
var run_active: bool = false
var display_state: int = DisplayState.NONE:
	set(value):
		if display_state == value:
			return
		display_state = value
		display_state_changed.emit(value)
		simulation_running_changed.emit(is_simulation_running())


var score: int = 0:
	set(value):
		score = value
		score_changed.emit()


var correct_answers: int = 0


func _ready() -> void:
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _process(delta: float) -> void:
	if not run_active:
		return
	if not is_timed_run():
		return
	if not is_simulation_running():
		return
	run_time_left = max(0.0, run_time_left - delta)
	run_time_changed.emit(run_time_left)
	if run_time_left == 0.0:
		run_active = false
		run_time_expired.emit()


func reset() -> void:
	score = 0
	correct_answers = 0
	highscore_rank = HighscoreManager.NO_RANK
	display_state = DisplayState.NONE
	spawn_point = SpawnPoint.START
	overworld_path = DEFAULT_OVERWORLD_PATH
	world_seed = NO_SEED
	reset_procedural_progression()
	run_time_left = 0.0
	run_active = false


func set_overworld_path(path: String) -> void:
	overworld_path = path


func get_or_create_world_seed() -> int:
	while world_seed == NO_SEED:
		world_seed = randi()
	return world_seed


func start_procedural_run() -> Dictionary:
	reset_procedural_progression()
	return get_or_create_procedural_level_config(FIRST_PROCEDURAL_LEVEL)


func reset_procedural_progression() -> void:
	procedural_level_index = FIRST_PROCEDURAL_LEVEL
	procedural_level_configs.clear()
	procedural_spawn_at_end = false


func get_or_create_procedural_level_config(level_index: int) -> Dictionary:
	if level_index < FIRST_PROCEDURAL_LEVEL:
		push_error("Procedural level index must be at least one.")
		return {}
	if procedural_level_configs.has(level_index):
		return procedural_level_configs[level_index].duplicate()

	var growth_steps := level_index - FIRST_PROCEDURAL_LEVEL
	@warning_ignore("integer_division")
	var max_growth_steps_x := (MAX_VECTOR2I_COMPONENT - FIRST_PROCEDURAL_LEVEL_SIZE.x) / PROCEDURAL_LEVEL_SIZE_INCREMENT.x
	@warning_ignore("integer_division")
	var max_growth_steps_y := (MAX_VECTOR2I_COMPONENT - FIRST_PROCEDURAL_LEVEL_SIZE.y) / PROCEDURAL_LEVEL_SIZE_INCREMENT.y
	if growth_steps > min(max_growth_steps_x, max_growth_steps_y):
		push_error("Procedural level size exceeds Vector2i limits.")
		return {}

	var level_seed := randi()
	while level_seed == NO_SEED:
		level_seed = randi()
	var level_size := FIRST_PROCEDURAL_LEVEL_SIZE + PROCEDURAL_LEVEL_SIZE_INCREMENT * growth_steps
	var level_config := {
		"seed": level_seed,
		"size": level_size
	}
	procedural_level_configs[level_index] = level_config
	return level_config.duplicate()


func is_hard() -> bool:
	return difficulty_level == DifficultyLevel.HARD


func is_simulation_running() -> bool:
	return display_state == DisplayState.NONE


func spawns_at_nether_portal() -> bool:
	return spawn_point == SpawnPoint.NETHER_PORTAL


func spawns_at_cave_entrance() -> bool:
	return spawn_point == SpawnPoint.CAVE_ENTRANCE


func toggle_difficulty_level() -> void:
	if difficulty_level == DifficultyLevel.NORMAL:
		difficulty_level = DifficultyLevel.HARD
	else:
		difficulty_level = DifficultyLevel.NORMAL


func is_timed_run() -> bool:
	return game_mode == GameMode.TIMED_RUN


func toggle_game_mode() -> void:
	if game_mode == GameMode.NORMAL:
		game_mode = GameMode.TIMED_RUN
	else:
		game_mode = GameMode.NORMAL


func start_run() -> void:
	if not is_timed_run():
		return
	run_time_left = run_duration_seconds
	run_active = true
	run_time_changed.emit(run_time_left)


func stop_run() -> void:
	run_active = false


func add_score(points: int) -> void:
	score += points
	var new_rank := HighscoreManager.get_rank(score)
	if new_rank != highscore_rank:
		highscore_rank = new_rank
		highscore_rank_changed.emit(highscore_rank)
	AchievementManager.track_score(score)


func _on_achievement_unlocked(achievement: AchievementManager.Achievement) -> void:
	if achievement.bonus > 0:
		add_score(achievement.bonus)
