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
	NETHER_PORTAL
}

const DEFAULT_OVERWORLD_PATH := "res://classic/overworld.tscn"
const NO_SEED := 0


signal score_changed
signal display_state_changed(state: int)
signal simulation_running_changed(running: bool)
signal entered_highscores


var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL
var spawn_point: SpawnPoint = SpawnPoint.START
var overworld_path: String = DEFAULT_OVERWORLD_PATH
var world_seed: int = NO_SEED
var has_entered_highscores: bool = false
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


func reset() -> void:
	score = 0
	correct_answers = 0
	has_entered_highscores = false
	display_state = DisplayState.NONE
	spawn_point = SpawnPoint.START
	overworld_path = DEFAULT_OVERWORLD_PATH
	world_seed = NO_SEED


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


func toggle_difficulty_level() -> void:
	if difficulty_level == DifficultyLevel.NORMAL:
		difficulty_level = DifficultyLevel.HARD
	else:
		difficulty_level = DifficultyLevel.NORMAL


func add_score(points: int) -> void:
	score += points
	if not has_entered_highscores and HighscoreManager.is_highscore(score):
		has_entered_highscores = true
		entered_highscores.emit()
	AchievementManager.track_score(score)


func _on_achievement_unlocked(achievement: AchievementManager.Achievement) -> void:
	if achievement.bonus > 0:
		add_score(achievement.bonus)
