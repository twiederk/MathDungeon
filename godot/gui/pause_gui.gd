class_name PauseGui
extends Control

@onready var pause_menu: PauseMenu = $PauseMenu


var paused = false:
	set(value):
		paused = value
		get_tree().paused = paused
		if paused:
			_show_menu()
		else:
			_hide_menus()


func _process(_delta) -> void:
	if Input.is_action_just_pressed("pause_menu"):
		paused = !paused


func _hide_menus() -> void:
	pause_menu.hide()


func _show_menu() -> void:
	pause_menu.show_menu()


func _on_menu_closed():
	paused = false
