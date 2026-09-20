extends Node


signal score_changed
signal eyes_of_ender_changed


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


func add_score(points: int) -> void:
	score += points
	AchievementManager.track_score(score)
