class_name PauseMenu
extends Control

@onready var resume_button = $CenterContainer/VBoxContainer/ResumeButton
@onready var quiz: Control = get_node("../QuizDialog")

var is_paused = false


func _ready():
	resume_button.grab_focus()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()


func toggle_pause_menu():
	if quiz.visible:
		return
		
	is_paused = !is_paused
	if is_paused:
		show_pause_menu()
	else:
		hide_pause_menu()


func show_pause_menu():
	visible = true
	get_tree().paused = true


func hide_pause_menu():
	visible = false
	get_tree().paused = false


func _on_resume_button_pressed():
	toggle_pause_menu()


func _on_start_gui_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
