class_name PauseMenu
extends Control

signal menu_closed()

@onready var resume_button = $CenterContainer/VBoxContainer/ResumeButton
@onready var quiz: Control = get_node("/root/Main/QuizDialog")


func _ready():
	pass


func show_menu():
	show()
	resume_button.grab_focus()


func _on_resume_button_pressed():
	menu_closed.emit()


func _on_start_gui_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
