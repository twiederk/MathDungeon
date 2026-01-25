class_name ScoreWidget
extends Control


var number_format = NumberFormat.new()


@onready var score_label = $ScoreLabel


func _ready() -> void:
	PlayerStats.score_changed.connect(_on_score_changed)
	update_score()


func _on_score_changed() -> void:
	update_score()


func update_score() -> void:
	score_label.text = "Punkte: " + number_format.format(PlayerStats.score)
