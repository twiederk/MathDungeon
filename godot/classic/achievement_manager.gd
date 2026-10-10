extends Node


signal achievement_unlocked(achievement: Achievement)


class Achievement:
	var title: String
	var desc: String
	var target: int
	var type: String
	var badge_graphic: String
	var bonus: int
	
	func _init(p_title: String, p_desc: String, p_target: int, p_type: String, p_badge_graphic: String = "", p_bonus: int = 0) -> void:
		title = p_title
		desc = p_desc
		target = p_target
		type = p_type
		badge_graphic = p_badge_graphic
		bonus = p_bonus


var ACHIEVEMENTS = {
	"score_1000": Achievement.new("Erste Tausend!", "Erreiche 1.000 Punkte", 1000, "score", "score_1000.png"),
	"score_2000": Achievement.new("Zweitausend!", "Erreiche 2.000 Punkte", 2000, "score", "score_2000.png"),
	"score_3000": Achievement.new("Dreitausend!", "Erreiche 3.000 Punkte", 3000, "score", "score_3000.png"),
	"score_5000": Achievement.new("Fünftausend!", "Erreiche 5.000 Punkte", 5000, "score", "score_5000.png"),
	"score_10000": Achievement.new("Zehntausend!", "Erreiche 10.000 Punkte", 10000, "score", "score_10000.png"),
	
	"enderman_1": Achievement.new("Erster Enderman besiegt!", "Besiege deinen ersten Enderman", 1, "enderman", "enderman_1.png"),
	"enderman_5": Achievement.new("Enderman-Jäger", "Besiege 5 Endermen", 5, "enderman", "enderman_5.png"),
	"enderman_10": Achievement.new("Enderman-Meister", "Besiege 10 Endermen", 10, "enderman", "enderman_10.png"),
	
	"enderdragon_1": Achievement.new("Drachentöter!", "Besiege deinen ersten Enderdrachen", 1, "enderdragon", "enderdragon_1.png"),
	"enderdragon_3": Achievement.new("Drachenjäger", "Besiege 3 Enderdrachen", 3, "enderdragon", "enderdragon_3.png"),
	"enderdragon_5": Achievement.new("Drachenmeister", "Besiege 5 Enderdrachen", 5, "enderdragon", "enderdragon_5.png"),
	
	"nether_1": Achievement.new("Ab in den Nether!", "Besuche den Nether zum ersten Mal", 1, "nether", "nether_1.png"),
	"nether_5": Achievement.new("Nether-Erkunder", "Besuche den Nether 5 Mal", 5, "nether", "nether_5.png"),
	"nether_10": Achievement.new("Nether-Meister", "Besuche den Nether 10 Mal", 10, "nether", "nether_10.png"),
	
	"woodland_mansion": Achievement.new("Waldanwesen erobert!", "Besiege alle Bewohner des Waldanwesens", 1, "woodland_mansion", "conquere_woodland_mansion.png", 1000),
	"nether_fortress": Achievement.new("Festung gesäubert!", "Besiege alle Gegner der Nether-Festung", 1, "nether_fortress", "conquere_nether_fortress.png", 1500),
	
	"dungeon_0": Achievement.new("Dungeon 1 gesäubert!", "Besiege alle Gegner im ersten Dungeon", 1, "dungeon_0", "conquere_dungeon.png", 500),
	"dungeon_1": Achievement.new("Dungeon 2 gesäubert!", "Besiege alle Gegner im zweiten Dungeon", 1, "dungeon_1", "conquere_dungeon.png", 500),
	"dungeon_2": Achievement.new("Dungeon 3 gesäubert!", "Besiege alle Gegner im dritten Dungeon", 1, "dungeon_2", "conquere_dungeon.png", 500),
	"dungeon_3": Achievement.new("Dungeon 4 gesäubert!", "Besiege alle Gegner im vierten Dungeon", 1, "dungeon_3", "conquere_dungeon.png", 500),
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

var _locations: Dictionary = {}


func clear_locations() -> void:
	_locations.clear()


func register_locations(enemies: Array) -> void:
	for enemy in enemies:
		if enemy is not Enemy or enemy.location == "":
			continue
		_locations[enemy.location] = _locations.get(enemy.location, 0) + 1


func track_score(new_score: int) -> void:
	progress["score"] = new_score
	_check_progress_achievements("score")


func track_enemy_defeat(enemy: Enemy) -> void:
	_track_enemy_type_defeat(enemy.stats.name)
	_track_location_defeat(enemy.location)


func _track_enemy_type_defeat(enemy_name: String) -> void:
	if enemy_name == "Enderman":
		progress["enderman"] += 1
		_check_progress_achievements("enderman")
	elif enemy_name == "Enderdragon":
		progress["enderdragon"] += 1
		_check_progress_achievements("enderdragon")


func _track_location_defeat(location: String) -> void:
	if not _locations.has(location):
		return
	_locations[location] -= 1
	if _locations[location] > 0:
		return
	_locations.erase(location)
	progress[location] = progress.get(location, 0) + 1
	_check_progress_achievements(location)


func track_nether_visit() -> void:
	progress["nether"] += 1
	_check_progress_achievements("nether")


func _check_progress_achievements(type: String) -> void:
	var current = progress.get(type, 0)
	var to_unlock: Array[String] = []
	
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id]
		if achievement.type == type:
			if current >= achievement.target and achievement_id not in unlocked_achievements:
				to_unlock.append(achievement_id)
	
	# unlocking may re-enter this function via score bonuses, so collect first
	for achievement_id in to_unlock:
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
	_locations.clear()
