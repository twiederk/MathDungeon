extends Node


signal achievement_unlocked(achievement: Achievement)


class Achievement:
	var title: String
	var desc: String
	var target: int
	var type: String
	var score: int
	var badge_graphic: String
	
	func _init(p_title: String, p_desc: String, p_target: int, p_type: String, p_score: int = 0, p_badge_graphic: String = "") -> void:
		title = p_title
		desc = p_desc
		target = p_target
		type = p_type
		score = p_score
		badge_graphic = p_badge_graphic


var ACHIEVEMENTS = {
	"score_1000": Achievement.new("Erste Tausend!", "Erreiche 1.000 Punkte", 1000, "score", 0, "badget_1000.png"),
	"score_2000": Achievement.new("Zweitausend!", "Erreiche 2.000 Punkte", 2000, "score", 0, "badget_2000.png"),
	"score_3000": Achievement.new("Dreitausend!", "Erreiche 3.000 Punkte", 3000, "score"),
	"score_5000": Achievement.new("Fünftausend!", "Erreiche 5.000 Punkte", 5000, "score"),
	"score_10000": Achievement.new("Zehntausend!", "Erreiche 10.000 Punkte", 10000, "score"),
	
	"enderman_1": Achievement.new("Erster Enderman besiegt!", "Besiege deinen ersten Enderman", 1, "enderman"),
	"enderman_5": Achievement.new("Enderman-Jäger", "Besiege 5 Endermen", 5, "enderman"),
	"enderman_10": Achievement.new("Enderman-Meister", "Besiege 10 Endermen", 10, "enderman"),
	
	"enderdragon_1": Achievement.new("Drachentöter!", "Besiege deinen ersten Enderdrachen", 1, "enderdragon"),
	"enderdragon_3": Achievement.new("Drachenjäger", "Besiege 3 Enderdrachen", 3, "enderdragon"),
	"enderdragon_5": Achievement.new("Drachenmeister", "Besiege 5 Enderdrachen", 5, "enderdragon"),
	
	"nether_1": Achievement.new("Ab in den Nether!", "Besuche den Nether zum ersten Mal", 1, "nether"),
	"nether_5": Achievement.new("Nether-Erkunder", "Besuche den Nether 5 Mal", 5, "nether"),
	"nether_10": Achievement.new("Nether-Meister", "Besuche den Nether 10 Mal", 10, "nether"),
}

var unlocked_achievements: Array[String] = []
var progress: Dictionary = {
	"score": 0,
	"enderman": 0,
	"enderdragon": 0,
	"nether": 0,
}

var recent_unlocks: Array[String] = []
const MAX_RECENT: int = 5



func track_score(new_score: int) -> void:
	progress["score"] = new_score
	_check_progress_achievements("score")


func track_enemy_defeat(enemy_name: String) -> void:
	if enemy_name == "Enderman":
		progress["enderman"] += 1
		_check_progress_achievements("enderman")
	elif enemy_name == "Enderdragon":
		progress["enderdragon"] += 1
		_check_progress_achievements("enderdragon")


func track_nether_visit() -> void:
	progress["nether"] += 1
	_check_progress_achievements("nether")


func _check_progress_achievements(type: String) -> void:
	var current = progress[type]
	
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id]
		if achievement.type == type:
			if current >= achievement.target and achievement_id not in unlocked_achievements:
				_unlock_achievement(achievement_id)


func _unlock_achievement(achievement_id: String) -> void:
	if achievement_id in unlocked_achievements:
		return
	
	unlocked_achievements.append(achievement_id)
	recent_unlocks.append(achievement_id)
	if recent_unlocks.size() > MAX_RECENT:
		recent_unlocks.pop_front()
	
	var achievement = ACHIEVEMENTS[achievement_id]
	achievement_unlocked.emit(achievement)


func get_recent_unlocks() -> Array[String]:
	return recent_unlocks


func reset() -> void:
	unlocked_achievements.clear()
	progress = {"score": 0, "enderman": 0, "enderdragon": 0, "nether": 0}
	recent_unlocks.clear()
