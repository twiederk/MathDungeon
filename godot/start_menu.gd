class_name StartMenu
extends Control


func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
