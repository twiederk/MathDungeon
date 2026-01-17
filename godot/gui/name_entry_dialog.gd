class_name NameEntryDialog
extends Control

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var name_line_edit: LineEdit = $CenterContainer/VBoxContainer/NameLineEdit
@onready var submit_button: Button = $CenterContainer/VBoxContainer/SubmitButton

var final_score: int = 0

signal name_submitted(player_name: String, score: int)


func open_for_score(score: int) -> void:
	final_score = score
	score_label.text = "Glückwunsch! Du hast alle Ghasts besiegt!\nDein Punktestand: %d\nGib deinen Namen ein (max. 10 Zeichen):" % score
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
	
	name_submitted.emit(player_name, final_score)
	_close_dialog()


func _close_dialog() -> void:
	visible = false
	get_tree().paused = false