extends GutTest

const HIGHSCORE_MENU_SCENE = preload("res://gui/highscore_menu.tscn")

var highscore_menu: HighscoreMenu


func before_each():
	highscore_menu = add_child_autofree(HIGHSCORE_MENU_SCENE.instantiate())


func after_each():
	highscore_menu = null
	GameSession.game_mode = GameSession.GameMode.NORMAL


func test_initial_displayed_mode_matches_the_game_mode():
	# assert
	assert_eq(highscore_menu.displayed_mode, GameSession.GameMode.NORMAL)


func test_initial_displayed_mode_matches_the_timed_run_game_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	
	# act
	var menu = add_child_autofree(HIGHSCORE_MENU_SCENE.instantiate())
	
	# assert
	assert_eq(menu.displayed_mode, GameSession.GameMode.TIMED_RUN)


func test_pressing_the_mode_button_switches_the_displayed_mode():
	# act
	highscore_menu._on_mode_button_pressed()
	
	# assert
	assert_eq(highscore_menu.displayed_mode, GameSession.GameMode.TIMED_RUN)


func test_pressing_the_mode_button_updates_the_label():
	# act
	highscore_menu._on_mode_button_pressed()
	
	# assert
	assert_eq(highscore_menu.mode_button.text, "Bestenliste: 10 min Lauf")
