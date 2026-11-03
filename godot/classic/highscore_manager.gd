extends Node

const HIGHSCORE_PATHS := {
	GameSession.GameMode.NORMAL: "user://high_scores",
	GameSession.GameMode.TIMED_RUN: "user://high_scores_10min"
}
const POINTS_PER_CORRECT_ANSWER: int = 10
const MAX_HIGHSCORES: int = 10

var highscores_by_mode: Dictionary = {
	GameSession.GameMode.NORMAL: [],
	GameSession.GameMode.TIMED_RUN: []
}

signal highscores_updated


func _ready():
	for mode in HIGHSCORE_PATHS.keys():
		_load_highscores(mode)


func add_score(player_name: String, score: int, difficulty_level: GameSession.DifficultyLevel = GameSession.DifficultyLevel.NORMAL, correct_answers: int = 0, mode: GameSession.GameMode = GameSession.game_mode) -> bool:
	var date_dict = Time.get_date_dict_from_system()
	var date_string = "%02d.%02d.%d" % [date_dict.day, date_dict.month, date_dict.year]
	var difficulty_string = "hard" if difficulty_level == GameSession.DifficultyLevel.HARD else "normal"
	var new_entry = Highscore.new(player_name, score, date_string, difficulty_string, correct_answers)
	
	var highscores: Array = highscores_by_mode[mode]
	highscores.append(new_entry)
	
	highscores.sort_custom(func(a, b): return a.score > b.score)
	
	if highscores.size() > MAX_HIGHSCORES:
		highscores = highscores.slice(0, MAX_HIGHSCORES)
	
	highscores_by_mode[mode] = highscores
	
	var made_highscore = false
	for entry in highscores:
		if entry.name == player_name and entry.score == score:
			made_highscore = true
			break
	
	_save_highscores(mode)
	highscores_updated.emit()
	
	return made_highscore


func get_highscores(mode: GameSession.GameMode = GameSession.game_mode) -> Array[Highscore]:
	var highscores: Array[Highscore] = []
	highscores.assign(highscores_by_mode[mode])
	return highscores


func is_highscore(score: int, mode: GameSession.GameMode = GameSession.game_mode) -> bool:
	var highscores: Array = highscores_by_mode[mode]
	if highscores.size() < MAX_HIGHSCORES:
		return true
	return score > highscores[MAX_HIGHSCORES - 1].score


func _save_highscores(mode: GameSession.GameMode) -> void:
	var save_file = FileAccess.open(HIGHSCORE_PATHS[mode], FileAccess.WRITE)
	if save_file == null:
		print("Error: Could not open highscore file for writing")
		return
	
	var highscores: Array = highscores_by_mode[mode]
	var data_string = JSON.stringify(highscores.map(func(entry): return entry.to_dict()))
	save_file.store_string(data_string)
	save_file.close()


func _load_highscores(mode: GameSession.GameMode) -> void:
	var path: String = HIGHSCORE_PATHS[mode]
	if not FileAccess.file_exists(path):
		highscores_by_mode[mode] = []
		return
	
	var load_file = FileAccess.open(path, FileAccess.READ)
	if load_file == null:
		print("Error: Could not open highscore file for reading")
		highscores_by_mode[mode] = []
		return
	
	var file_content = load_file.get_as_text()
	load_file.close()
	
	var parsed_data = JSON.parse_string(file_content)
	var highscores: Array[Highscore] = []
	if parsed_data != null and typeof(parsed_data) == TYPE_ARRAY:
		for data in parsed_data:
			highscores.append(Highscore.from_dict(data))
	highscores_by_mode[mode] = highscores
