extends Node


signal achievement_unlocked(achievement_id: String, title: String, description: String)
signal achievement_progress(achievement_id: String, current: int, target: int)

const SAVE_PATH: String = "user://achievements.save"

const ACHIEVEMENTS = {
	"score_1000": {"title": "Erste Tausend!", "desc": "Erreiche 1.000 Punkte", "target": 1000, "type": "score"},
	"score_2000": {"title": "Zweitausend!", "desc": "Erreiche 2.000 Punkte", "target": 2000, "type": "score"},
	"score_3000": {"title": "Dreitausend!", "desc": "Erreiche 3.000 Punkte", "target": 3000, "type": "score"},
	"score_5000": {"title": "Fünftausend!", "desc": "Erreiche 5.000 Punkte", "target": 5000, "type": "score"},
	"score_10000": {"title": "Zehntausend!", "desc": "Erreiche 10.000 Punkte", "target": 10000, "type": "score"},
	
	"enderman_1": {"title": "Erster Enderman besiegt!", "desc": "Besiege deinen ersten Enderman", "target": 1, "type": "enderman"},
	"enderman_5": {"title": "Enderman-Jäger", "desc": "Besiege 5 Endermen", "target": 5, "type": "enderman"},
	"enderman_10": {"title": "Enderman-Meister", "desc": "Besiege 10 Endermen", "target": 10, "type": "enderman"},
	
	"enderdragon_1": {"title": "Drachentöter!", "desc": "Besiege deinen ersten Enderdrachen", "target": 1, "type": "enderdragon"},
	"enderdragon_3": {"title": "Drachenjäger", "desc": "Besiege 3 Enderdrachen", "target": 3, "type": "enderdragon"},
	"enderdragon_5": {"title": "Drachenmeister", "desc": "Besiege 5 Enderdrachen", "target": 5, "type": "enderdragon"},
	
	"nether_1": {"title": "Ab in den Nether!", "desc": "Besuche den Nether zum ersten Mal", "target": 1, "type": "nether"},
	"nether_5": {"title": "Nether-Erkunder", "desc": "Besuche den Nether 5 Mal", "target": 5, "type": "nether"},
	"nether_10": {"title": "Nether-Meister", "desc": "Besuche den Nether 10 Mal", "target": 10, "type": "nether"},
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
		if achievement["type"] == type:
			if current >= achievement["target"] and achievement_id not in unlocked_achievements:
				_unlock_achievement(achievement_id)
			elif current < achievement["target"]:
				achievement_progress.emit(achievement_id, current, achievement["target"])


func _unlock_achievement(achievement_id: String) -> void:
	if achievement_id in unlocked_achievements:
		return
	
	unlocked_achievements.append(achievement_id)
	recent_unlocks.append(achievement_id)
	if recent_unlocks.size() > MAX_RECENT:
		recent_unlocks.pop_front()
	
	var achievement = ACHIEVEMENTS[achievement_id]
	achievement_unlocked.emit(achievement_id, achievement["title"], achievement["desc"])


func get_recent_unlocks() -> Array[String]:
	return recent_unlocks


func reset() -> void:
	unlocked_achievements.clear()
	progress = {"score": 0, "enderman": 0, "enderdragon": 0, "nether": 0}
	recent_unlocks.clear()
