extends Node


signal achievement_unlocked(achievement: Achievement)


class Achievement:
	var title: String
	var desc: String
	var target: int
	var type: String
	var badge_graphic: String
	var bonus: int
	var repeatable: bool
	
	func _init(p_title: String, p_desc: String, p_target: int, p_type: String, p_badge_graphic: String = "", p_bonus: int = 0, p_repeatable: bool = false) -> void:
		title = p_title
		desc = p_desc
		target = p_target
		type = p_type
		badge_graphic = p_badge_graphic
		bonus = p_bonus
		repeatable = p_repeatable


var ACHIEVEMENTS = {
	"eyes_4": Achievement.new("Enderman-Besieger", "Sammle 4 Enderaugen", 4, "eyes_of_ender", "eyes_of_ender.png", 250),
	"eyes_8": Achievement.new("Enderman-Jäger", "Sammle 8 Enderaugen", 8, "eyes_of_ender", "eyes_of_ender.png", 500),
	"eyes_12": Achievement.new("Enderman-Meister", "Sammle 12 Enderaugen", 12, "eyes_of_ender", "eyes_of_ender.png", 1000),	
	"lighter": Achievement.new("Feuerzeug gefunden!", "Finde das Feuerzeug", 1, "lighter", "lighter.png", 250),
	"enderdragon": Achievement.new("Drachentöter!", "Besiege deinen ersten Enderdrachen", 1, "enderdragon", "enderdragon.png", 1000),
	"nether": Achievement.new("Ab in den Nether!", "Besuche den Nether zum ersten Mal", 1, "nether", "nether.png", 1000),
	"woodland_mansion": Achievement.new("Waldanwesen erobert!", "Besiege alle Bewohner des Waldanwesens", 1, "woodland_mansion", "conquere_woodland_mansion.png", 1000),
	"nether_fortress": Achievement.new("Nether-Festung erobert!", "Besiege alle Gegner der Nether-Festung", 1, "nether_fortress", "conquere_nether_fortress.png", 1500),
	"dungeon": Achievement.new("Dungeon gesäubert!", "Besiege alle Gegner eines Dungeons", 1, "dungeon", "conquere_dungeon.png", 500, true),
}

var unlocked_achievements: Array[String] = []
var progress: Dictionary = {
	"score": 0,
	"eyes_of_ender": 0,
	"lighter": 0,
	"enderdragon": 0,
	"nether": 0,
}

var recent_unlocks: Array[String] = []
const MAX_RECENT: int = 5

var _locations: Dictionary = {}


func _ready() -> void:
	GameSession.eyes_of_ender_changed.connect(_on_eyes_of_ender_changed)
	GameSession.has_lighter_changed.connect(_on_has_lighter_changed)


func _on_eyes_of_ender_changed() -> void:
	_set_progress("eyes_of_ender", GameSession.eyes_of_ender)


func _on_has_lighter_changed() -> void:
	_set_progress("lighter", 1 if GameSession.has_lighter else 0)


func clear_locations() -> void:
	_locations.clear()


func register_locations(enemies: Array) -> void:
	for enemy in enemies:
		if enemy is not Enemy or enemy.location == "":
			continue
		_locations[enemy.location] = _locations.get(enemy.location, 0) + 1


func track_score(new_score: int) -> void:
	_set_progress("score", new_score)


func track_enemy_defeat(enemy: Enemy) -> void:
	_track_enemy_type_defeat(enemy.stats.name)
	_track_location_defeat(enemy.location)


func _track_enemy_type_defeat(enemy_name: String) -> void:
	if enemy_name == "Enderdragon":
		progress["enderdragon"] += 1
		_check_progress_achievements("enderdragon")


func _track_location_defeat(location: String) -> void:
	if not _locations.has(location):
		return
	_locations[location] -= 1
	if _locations[location] > 0:
		return
	_locations.erase(location)
	var type = _location_to_type(location)
	progress[type] = progress.get(type, 0) + 1
	_check_progress_achievements(type)


# Enemies are counted per dungeon, but all dungeons share one achievement.
func _location_to_type(location: String) -> String:
	return "dungeon" if location.begins_with("dungeon") else location


func track_nether_visit() -> void:
	progress["nether"] += 1
	_check_progress_achievements("nether")


func _set_progress(type: String, value: int) -> void:
	progress[type] = value
	_check_progress_achievements(type)


func _check_progress_achievements(type: String) -> void:
	var current = progress.get(type, 0)
	var to_unlock: Array[String] = []
	
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id]
		if achievement.type == type:
			if current >= achievement.target and _can_unlock(achievement_id):
				to_unlock.append(achievement_id)
	
	# unlocking may re-enter this function via score bonuses, so collect first
	for achievement_id in to_unlock:
		_unlock_achievement(achievement_id)


func _can_unlock(achievement_id: String) -> bool:
	return achievement_id not in unlocked_achievements or ACHIEVEMENTS[achievement_id].repeatable


func _unlock_achievement(achievement_id: String) -> void:
	if not _can_unlock(achievement_id):
		return
	
	if achievement_id not in unlocked_achievements:
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
	progress = {"score": 0, "eyes_of_ender": 0, "lighter": 0, "enderdragon": 0, "nether": 0}
	recent_unlocks.clear()
	_locations.clear()
