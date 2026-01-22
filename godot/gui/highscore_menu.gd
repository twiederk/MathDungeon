class_name HighscoreMenu
extends Control


@onready var back_button = $BackButton
@onready var highscore_display: Label = $CenterContainer/VBoxContainer/HighscoreDisplay


func _ready():
	back_button.grab_focus()
	_update_highscore_display()
	HighscoreManager.highscores_updated.connect(_update_highscore_display)


func _update_highscore_display():
	highscore_display.text = HighscoreManager.get_formatted_highscores()


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")
