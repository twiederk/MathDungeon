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


signal score_changed
signal display_state_changed(state: int)
signal simulation_running_changed(running: bool)


var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL
var spawn_point: SpawnPoint = SpawnPoint.START
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
	display_state = DisplayState.NONE
	spawn_point = SpawnPoint.START


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
	AchievementManager.track_score(score)


func _on_achievement_unlocked(achievement: AchievementManager.Achievement) -> void:
	if achievement.bonus > 0:
		add_score(achievement.bonus)
