class_name NameEntryDialog
extends Control

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var name_line_edit: LineEdit = $CenterContainer/VBoxContainer/NameLineEdit
@onready var submit_button: Button = $CenterContainer/VBoxContainer/SubmitButton

var final_score: int = 0


func _ready():
	get_tree().paused = false


func open_for_score(score: int) -> void:
	final_score = score
	score_label.text = "Glückwunsch!\nDein Punktestand: %d\nGib deinen Namen ein (max. 10 Zeichen):" % score
	name_line_edit.text = ""
	name_line_edit.max_length = 10
	visible = true
	name_line_edit.grab_focus()
	get_tree().paused = true


func _on_submit_button_pressed() -> void:
	_submit_name()


func _on_name_line_edit_text_submitted(_text: String) -> void:
	_submit_name()


func _submit_name() -> void:
	var player_name = name_line_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "SPIELER"
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")
