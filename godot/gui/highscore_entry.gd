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


func setup(rank: int, highscore: Highscore) -> void:
	rank_name_label.text = "%d. %s" % [rank, highscore.name]
	score_label.text = "%s" % number_format.format(highscore.score)
	correct_answers_label.text = "%d richtig" % highscore.correct_answers
	date_label.text = highscore.date
	difficulty_label.text = DIFFICULTY_LABELS.get(highscore.difficulty_level, "")
