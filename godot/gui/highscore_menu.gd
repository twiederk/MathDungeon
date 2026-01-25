class_name HighscoreMenu
extends Control


var number_format = NumberFormat.new()

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
		var hbox = HBoxContainer.new()
		
		var rank_name_label = Label.new()
		rank_name_label.text = "%d. %s" % [i + 1, entry.name]
		rank_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var score_label = Label.new()
		score_label.text = "%s" % number_format.format(entry.score)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_label.custom_minimum_size.x = 100
		
		hbox.add_child(rank_name_label)
		hbox.add_child(score_label)
		highscore_container.add_child(hbox)


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")
