class_name PauseGui
extends Control

@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	GameSession.display_state_changed.connect(_on_display_state_changed)
	_on_display_state_changed(GameSession.display_state)


func _process(_delta) -> void:
	if Input.is_action_just_pressed("pause_menu"):
		match GameSession.display_state:
			GameSession.DisplayState.QUIZ_DIALOG:
				return
			GameSession.DisplayState.PAUSE_MENU:
				GameSession.display_state = GameSession.DisplayState.NONE
				get_tree().paused = false
			GameSession.DisplayState.NONE, GameSession.DisplayState.QUEST_LOG, GameSession.DisplayState.CHARACTER_SHEET:
				GameSession.display_state = GameSession.DisplayState.PAUSE_MENU
				get_tree().paused = true


func _hide_menus() -> void:
	pause_menu.hide()


func _show_menu() -> void:
	pause_menu.show_menu()


func _on_menu_closed():
	GameSession.display_state = GameSession.DisplayState.NONE
	get_tree().paused = false


func _on_display_state_changed(state: int) -> void:
	if state == GameSession.DisplayState.PAUSE_MENU:
		_show_menu()
	else:
		_hide_menus()
