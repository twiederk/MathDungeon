class_name HighscoreMenu
extends Control


const HighscoreEntryScene := preload("res://gui/highscore_entry.tscn")

@onready var back_button = $BackButton
@onready var highscore_container: VBoxContainer = $CenterContainer/VBoxContainer/HighscoreContainer


func _ready():
	back_button.grab_focus()
	_update_highscore_display()
	HighscoreManager.highscores_updated.connect(_update_highscore_display)


func _update_highscore_display():
	# Clear existing entries
	for child in highscore_container.get_children():
		child.queue_free()
	
	if HighscoreManager.highscores.is_empty():
		var no_scores_label = Label.new()
		no_scores_label.text = "Noch keine Einträge"
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		highscore_container.add_child(no_scores_label)
		return
	
	# Add each highscore entry
	for i in range(HighscoreManager.highscores.size()):
		var entry = HighscoreManager.highscores[i]
		var entry_row: HighscoreEntry = HighscoreEntryScene.instantiate()
		highscore_container.add_child(entry_row)
		var rank = i + 1
		entry_row.setup(rank, entry)


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")
