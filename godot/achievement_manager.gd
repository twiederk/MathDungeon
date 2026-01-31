extends Node

## Achievement Manager
## Tracks player achievements including score milestones, enemy defeats, and location visits

signal achievement_unlocked(achievement_id: String, title: String, description: String)
signal achievement_progress(achievement_id: String, current: int, target: int)

const SAVE_PATH: String = "user://achievements.save"

## Achievement definitions
const ACHIEVEMENTS = {
	# Score milestones (every 1,000 points)
	"score_1000": {"title": "First Thousand!", "desc": "Score 1,000 points", "target": 1000, "type": "score"},
	"score_2000": {"title": "Two Thousand!", "desc": "Score 2,000 points", "target": 2000, "type": "score"},
	"score_3000": {"title": "Three Thousand!", "desc": "Score 3,000 points", "target": 3000, "type": "score"},
	"score_5000": {"title": "Five Thousand!", "desc": "Score 5,000 points", "target": 5000, "type": "score"},
	"score_10000": {"title": "Ten Thousand!", "desc": "Score 10,000 points", "target": 10000, "type": "score"},
	
	# Enderman defeats
	"enderman_1": {"title": "First Enderman Defeated!", "desc": "Defeat your first Enderman", "target": 1, "type": "enderman"},
	"enderman_5": {"title": "Enderman Hunter", "desc": "Defeat 5 Endermen", "target": 5, "type": "enderman"},
	"enderman_10": {"title": "Enderman Master", "desc": "Defeat 10 Endermen", "target": 10, "type": "enderman"},
	
	# Enderdragon defeats
	"enderdragon_1": {"title": "Dragon Slayer!", "desc": "Defeat your first Enderdragon", "target": 1, "type": "enderdragon"},
	"enderdragon_3": {"title": "Dragon Hunter", "desc": "Defeat 3 Enderdragons", "target": 3, "type": "enderdragon"},
	"enderdragon_5": {"title": "Dragon Master", "desc": "Defeat 5 Enderdragons", "target": 5, "type": "enderdragon"},
	
	# Nether visits
	"nether_1": {"title": "Into the Nether!", "desc": "Visit the Nether for the first time", "target": 1, "type": "nether"},
	"nether_5": {"title": "Nether Explorer", "desc": "Visit the Nether 5 times", "target": 5, "type": "nether"},
	"nether_10": {"title": "Nether Master", "desc": "Visit the Nether 10 times", "target": 10, "type": "nether"},
}

## Tracking data
var unlocked_achievements: Array[String] = []
var progress: Dictionary = {
	"score": 0,
	"enderman": 0,
	"enderdragon": 0,
	"nether": 0,
}

## Recently unlocked achievements (for badge display)
var recent_unlocks: Array[String] = []
const MAX_RECENT: int = 5


func _ready() -> void:
	load_achievements()


## Track score progress and check for milestones
func track_score(new_score: int) -> void:
	var old_score = progress["score"]
	progress["score"] = new_score
	
	# Check all score achievements
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id]
		if achievement["type"] == "score":
			if new_score >= achievement["target"] and old_score < achievement["target"]:
				_unlock_achievement(achievement_id)


## Track enemy defeats
func track_enemy_defeat(enemy_name: String) -> void:
	if enemy_name == "Enderman":
		progress["enderman"] += 1
		_check_progress_achievements("enderman")
	elif enemy_name == "Enderdragon":
		progress["enderdragon"] += 1
		_check_progress_achievements("enderdragon")


## Track Nether visits
func track_nether_visit() -> void:
	progress["nether"] += 1
	_check_progress_achievements("nether")


## Check if any achievements of given type should be unlocked
func _check_progress_achievements(type: String) -> void:
	var current = progress[type]
	
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id]
		if achievement["type"] == type:
			if current >= achievement["target"] and achievement_id not in unlocked_achievements:
				_unlock_achievement(achievement_id)
			elif current < achievement["target"]:
				# Emit progress update
				achievement_progress.emit(achievement_id, current, achievement["target"])


## Unlock an achievement
func _unlock_achievement(achievement_id: String) -> void:
	if achievement_id in unlocked_achievements:
		return
	
	unlocked_achievements.append(achievement_id)
	recent_unlocks.append(achievement_id)
	if recent_unlocks.size() > MAX_RECENT:
		recent_unlocks.pop_front()
	
	var achievement = ACHIEVEMENTS[achievement_id]
	achievement_unlocked.emit(achievement_id, achievement["title"], achievement["desc"])
	
	save_achievements()


## Get recent unlocked achievements for badge display
func get_recent_unlocks() -> Array[String]:
	return recent_unlocks


## Check if achievement is unlocked
func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked_achievements


## Get all achievements with unlock status
func get_all_achievements() -> Array:
	var result = []
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id].duplicate()
		achievement["id"] = achievement_id
		achievement["unlocked"] = is_unlocked(achievement_id)
		achievement["current"] = progress.get(achievement["type"], 0)
		result.append(achievement)
	return result


## Save achievements to disk
func save_achievements() -> void:
	var data = {
		"unlocked": unlocked_achievements,
		"progress": progress,
		"recent": recent_unlocks,
	}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file:
		var data_string = JSON.stringify(data)
		save_file.store_string(data_string)
		save_file.close()


## Load achievements from disk
func load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var load_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if load_file:
		var data_string = load_file.get_as_text()
		load_file.close()
		
		var data = JSON.parse_string(data_string)
		if data:
			unlocked_achievements = data.get("unlocked", [])
			progress = data.get("progress", {"score": 0, "enderman": 0, "enderdragon": 0, "nether": 0})
			recent_unlocks = data.get("recent", [])


## Reset all achievements (for testing or new game)
func reset_achievements() -> void:
	unlocked_achievements.clear()
	progress = {"score": 0, "enderman": 0, "enderdragon": 0, "nether": 0}
	recent_unlocks.clear()
	save_achievements()
