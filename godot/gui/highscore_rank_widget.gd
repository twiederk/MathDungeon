class_name HighscoreRankWidget
extends Control


const NO_RANK_TEXT := "Kein Bestwert"

@onready var rank_label: Label = $RankLabel


func _ready() -> void:
	GameSession.highscore_rank_changed.connect(_on_highscore_rank_changed)
	update_rank()


func _on_highscore_rank_changed(_rank: int) -> void:
	update_rank()


func update_rank() -> void:
	rank_label.text = format_rank(GameSession.highscore_rank)


func format_rank(rank: int) -> String:
	if rank == HighscoreManager.NO_RANK:
		return NO_RANK_TEXT
	return "%d. Rang" % rank
