extends GutTest

const START_MENU_SCENE = preload("res://gui/start_menu.tscn")

var start_menu: StartMenu


func before_each():
	start_menu = add_child_autofree(START_MENU_SCENE.instantiate())


func after_each():
	GameSession.game_mode = GameSession.GameMode.NORMAL
	start_menu = null


func test_game_mode_button_text_matches_normal_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.NORMAL
	
	# act
	start_menu._update_game_mode_button()
	
	# assert
	assert_eq(start_menu.game_mode_button.text, "Spielmodus: normal")


func test_game_mode_button_text_matches_timed_run_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	
	# act
	start_menu._update_game_mode_button()
	
	# assert
	assert_eq(start_menu.game_mode_button.text, "Spielmodus: 10 min Lauf")


func test_pressing_the_button_switches_the_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.NORMAL
	
	# act
	start_menu._on_game_mode_button_pressed()
	
	# assert
	assert_eq(GameSession.game_mode, GameSession.GameMode.TIMED_RUN)


func test_pressing_the_button_updates_the_label():
	# arrange
	GameSession.game_mode = GameSession.GameMode.NORMAL
	
	# act
	start_menu._on_game_mode_button_pressed()
	
	# assert
	assert_eq(start_menu.game_mode_button.text, "Spielmodus: 10 min Lauf")
