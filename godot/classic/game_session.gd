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


signal score_changed
signal display_state_changed(state: int)
signal simulation_running_changed(running: bool)
signal entered_highscores
signal run_time_changed(seconds_left: float)
signal run_time_expired


var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL
var spawn_point: SpawnPoint = SpawnPoint.START
var overworld_path: String = DEFAULT_OVERWORLD_PATH
var world_seed: int = NO_SEED
var has_entered_highscores: bool = false
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
	has_entered_highscores = false
	display_state = DisplayState.NONE
	spawn_point = SpawnPoint.START
	overworld_path = DEFAULT_OVERWORLD_PATH
	world_seed = NO_SEED
	run_time_left = 0.0
	run_active = false


func set_overworld_path(path: String) -> void:
	overworld_path = path


func get_or_create_world_seed() -> int:
	while world_seed == NO_SEED:
		world_seed = randi()
	return world_seed


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
	if not has_entered_highscores and HighscoreManager.is_highscore(score):
		has_entered_highscores = true
		entered_highscores.emit()
	AchievementManager.track_score(score)


func _on_achievement_unlocked(achievement: AchievementManager.Achievement) -> void:
	if achievement.bonus > 0:
		add_score(achievement.bonus)
