extends Node

const HIGHSCORE_PATH: String = "user://high_scores"
const POINTS_PER_CORRECT_ANSWER: int = 10
const MAX_HIGHSCORES: int = 10

var highscores: Array = []

signal highscores_updated


func _ready():
	_load_highscores()


func add_score(player_name: String, score: int) -> bool:
	var new_entry = {"name": player_name, "score": score}
	
	# Add the new score
	highscores.append(new_entry)
	
	# Sort by score (highest first)
	highscores.sort_custom(func(a, b): return a.score > b.score)
	
	# Keep only top 10
	if highscores.size() > MAX_HIGHSCORES:
		highscores = highscores.slice(0, MAX_HIGHSCORES)
	
	# Check if the score made it to the top 10
	var made_highscore = false
	for entry in highscores:
		if entry.name == player_name and entry.score == score:
			made_highscore = true
			break
	
	_save_highscores()
	highscores_updated.emit()
	
	return made_highscore


func get_highscores() -> Array:
	return highscores.duplicate()


func is_highscore(score: int) -> bool:
	if highscores.size() < MAX_HIGHSCORES:
		return true
	return score > highscores[MAX_HIGHSCORES - 1].score


func get_formatted_highscores() -> String:
	var result = "Bestenliste:\n"
	if highscores.is_empty():
		result += "Noch keine Einträge"
		return result
	
	for i in range(min(5, highscores.size())):  # Show top 5
		var entry = highscores[i]
		result += "%d. %s - %d\n" % [i + 1, entry.name, entry.score]
	
	return result


func _save_highscores():
	var save_file = FileAccess.open(HIGHSCORE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("Error: Could not open highscore file for writing")
		return
	
	var data_string = JSON.stringify(highscores)
	save_file.store_string(data_string)
	save_file.close()


func _load_highscores():
	if not FileAccess.file_exists(HIGHSCORE_PATH):
		highscores = []
		return
	
	var load_file = FileAccess.open(HIGHSCORE_PATH, FileAccess.READ)
	if load_file == null:
		print("Error: Could not open highscore file for reading")
		highscores = []
		return
	
	var file_content = load_file.get_as_text()
	load_file.close()
	
	var parsed_data = JSON.parse_string(file_content)
	if parsed_data != null and typeof(parsed_data) == TYPE_ARRAY:
		highscores = parsed_data
	else:
		highscores = []