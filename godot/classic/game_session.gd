extends Node


enum DifficultyLevel {
	NORMAL,
	HARD
}


signal score_changed
signal eyes_of_ender_changed


var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL
var quiz_dialog_displayed: bool = false


var eyes_of_ender: int = 0:
	set(value):
		eyes_of_ender = value
		eyes_of_ender_changed.emit()


var score: int = 0:
	set(value):
		score = value
		score_changed.emit()


func reset() -> void:
	score = 0
	eyes_of_ender = 0


func is_hard() -> bool:
	return difficulty_level == DifficultyLevel.HARD


func toggle_difficulty_level() -> void:
	if difficulty_level == DifficultyLevel.NORMAL:
		difficulty_level = DifficultyLevel.HARD
	else:
		difficulty_level = DifficultyLevel.NORMAL


func add_score(points: int) -> void:
	score += points
	AchievementManager.track_score(score)
