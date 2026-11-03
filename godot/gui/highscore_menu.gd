class_name HighscoreMenu
extends Control


const HighscoreEntryScene := preload("res://gui/highscore_entry.tscn")
const MODE_LABELS := {
	GameSession.GameMode.NORMAL: "Bestenliste: normal",
	GameSession.GameMode.TIMED_RUN: "Bestenliste: 10 min Lauf"
}

var displayed_mode: GameSession.GameMode

@onready var back_button = $BackButton
@onready var mode_button: Button = $CenterContainer/VBoxContainer/ModeButton
@onready var highscore_container: VBoxContainer = $CenterContainer/VBoxContainer/HighscoreContainer


func _ready():
	displayed_mode = GameSession.game_mode
	_update_mode_button()
	back_button.grab_focus()
	_update_highscore_display()
	HighscoreManager.highscores_updated.connect(_update_highscore_display)


func _on_mode_button_pressed() -> void:
	if displayed_mode == GameSession.GameMode.NORMAL:
		displayed_mode = GameSession.GameMode.TIMED_RUN
	else:
		displayed_mode = GameSession.GameMode.NORMAL
	_update_mode_button()
	_update_highscore_display()


func _update_mode_button() -> void:
	mode_button.text = MODE_LABELS[displayed_mode]


func _update_highscore_display():
	for child in highscore_container.get_children():
		child.queue_free()
	
	var highscores := HighscoreManager.get_highscores(displayed_mode)
	if highscores.is_empty():
		var no_scores_label = Label.new()
		no_scores_label.text = "Noch keine Einträge"
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		highscore_container.add_child(no_scores_label)
		return
	
	for i in range(highscores.size()):
		var entry = highscores[i]
		var entry_row: HighscoreEntry = HighscoreEntryScene.instantiate()
		highscore_container.add_child(entry_row)
		var rank = i + 1
		entry_row.setup(rank, entry)


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")
