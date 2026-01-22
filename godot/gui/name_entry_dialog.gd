class_name NameEntryDialog
extends Control

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var name_line_edit: LineEdit = $CenterContainer/VBoxContainer/NameLineEdit
@onready var submit_button: Button = $CenterContainer/VBoxContainer/SubmitButton


func _ready():
	score_label.text = "Glückwunsch!\nDein Punktestand: %d\nGib deinen Namen ein:" % PlayerStats.current_score
	name_line_edit.text = ""
	name_line_edit.grab_focus()


func _on_submit_button_pressed() -> void:
	_submit_name()


func _on_name_line_edit_text_submitted(_text: String) -> void:
	_submit_name()


func _submit_name() -> void:
	var player_name = name_line_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "SPIELER"
	HighscoreManager.add_score(player_name, PlayerStats.current_score)
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")
