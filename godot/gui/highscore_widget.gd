class_name HighscoreWidget
extends Control

@onready var highscore_label = $HighscoreLabel


func _ready():
	_update_highscore_display()
	HighscoreManager.highscores_updated.connect(_update_highscore_display)


func _update_highscore_display():
	highscore_label.text = HighscoreManager.get_formatted_highscores()
