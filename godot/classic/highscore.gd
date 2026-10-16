class_name Highscore


var name: String
var score: int
var date: String
var difficulty_level: String
var correct_answers: int


func _init(_name: String = "", _score: int = 0, _date: String = "", _difficulty_level: String = "normal", _correct_answers: int = 0) -> void:
	name = _name
	score = _score
	date = _date
	difficulty_level = _difficulty_level
	correct_answers = _correct_answers


static func from_dict(data: Dictionary) -> Highscore:
	return Highscore.new(
		data.get("name", ""),
		int(data.get("score", 0)),
		data.get("date", "---"),
		data.get("difficulty_level", ""),
		int(data.get("correct_answers", 0))
	)


func to_dict() -> Dictionary:
	return {
		"name": name,
		"score": score,
		"date": date,
		"difficulty_level": difficulty_level,
		"correct_answers": correct_answers,
	}
