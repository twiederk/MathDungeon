class_name HighscoreEntry
extends HBoxContainer


const DIFFICULTY_LABELS := {
	"normal": "Normal",
	"hard": "Schwer",
}

var number_format = NumberFormat.new()

@onready var rank_name_label: Label = $RankNameLabel
@onready var score_label: Label = $ScoreLabel
@onready var correct_answers_label: Label = $CorrectAnswersLabel
@onready var date_label: Label = $DateLabel
@onready var difficulty_label: Label = $DifficultyLabel


func setup(rank: int, entry: Dictionary) -> void:
	rank_name_label.text = "%d. %s" % [rank, entry.name]
	score_label.text = "%s" % number_format.format(entry.score)
	correct_answers_label.text = "%d richtig" % entry.get("correct_answers", 0)
	date_label.text = entry.get("date", "---")
	difficulty_label.text = DIFFICULTY_LABELS.get(entry.get("difficulty_level", ""), "")
