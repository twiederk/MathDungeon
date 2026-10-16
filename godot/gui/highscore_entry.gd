class_name HighscoreEntry
extends HBoxContainer


const DIFFICULTY_LABELS := {
	"normal": "Normal",
	"hard": "Schwer",
}

var number_format = NumberFormat.new()

@onready var rank_label: Label = $RankLabel
@onready var name_label: Label = $NameLabel
@onready var score_label: Label = $ScoreLabel
@onready var correct_answers_label: Label = $CorrectAnswersLabel
@onready var date_label: Label = $DateLabel
@onready var difficulty_label: Label = $DifficultyLabel


func setup(rank: int, highscore: Highscore) -> void:
	rank_label.text = "%d." % rank
	name_label.text = highscore.name
	score_label.text = "%s" % number_format.format(highscore.score)
	correct_answers_label.text = "%d" % highscore.correct_answers
	date_label.text = highscore.date
	difficulty_label.text = DIFFICULTY_LABELS.get(highscore.difficulty_level, "")
