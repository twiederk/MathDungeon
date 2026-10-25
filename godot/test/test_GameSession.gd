extends GutTest

func after_each():
	GameSession.difficulty_level = GameSession.DifficultyLevel.NORMAL
	GameSession.display_state = GameSession.DisplayState.NONE


func test_reset():
	# act
	GameSession.reset()
	
	# assert
	assert_eq(0, GameSession.score)


func test_reset_restores_the_start_spawn_point():
	# arrange
	GameSession.spawn_point = GameSession.SpawnPoint.NETHER_PORTAL
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(GameSession.spawn_point, GameSession.SpawnPoint.START)


func test_toggle_difficulty_level():
	# arrange
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# act
	GameSession.toggle_difficulty_level()
	
	# assert
	assert_eq(GameSession.difficulty_level, GameSession.DifficultyLevel.NORMAL)


func test_reset_keeps_difficulty_level():
	# arrange
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(GameSession.difficulty_level, GameSession.DifficultyLevel.HARD)


func test_simulation_running_when_display_state_is_none():
	# arrange
	GameSession.display_state = GameSession.DisplayState.NONE
	
	# act
	var running = GameSession.is_simulation_running()
	
	# assert
	assert_true(running)


func test_simulation_not_running_during_quiz_dialog():
	# arrange
	GameSession.display_state = GameSession.DisplayState.QUIZ_DIALOG
	
	# act
	var running = GameSession.is_simulation_running()
	
	# assert
	assert_false(running)


func test_simulation_not_running_during_pause_menu():
	# arrange
	GameSession.display_state = GameSession.DisplayState.PAUSE_MENU
	
	# act
	var running = GameSession.is_simulation_running()
	
	# assert
	assert_false(running)


func test_simulation_not_running_during_quest_log():
	# arrange
	GameSession.display_state = GameSession.DisplayState.QUEST_LOG
	
	# act
	var running = GameSession.is_simulation_running()
	
	# assert
	assert_false(running)


func test_simulation_not_running_during_character_sheet():
	# arrange
	GameSession.display_state = GameSession.DisplayState.CHARACTER_SHEET
	
	# act
	var running = GameSession.is_simulation_running()
	
	# assert
	assert_false(running)


func test_simulation_running_changed_emits_false_when_dialog_opens():
	# arrange
	watch_signals(GameSession)
	
	# act
	GameSession.display_state = GameSession.DisplayState.QUIZ_DIALOG
	
	# assert
	assert_signal_emitted_with_parameters(GameSession, "simulation_running_changed", [false])


func test_simulation_running_changed_emits_true_when_returning_to_none():
	# arrange
	GameSession.display_state = GameSession.DisplayState.QUIZ_DIALOG
	watch_signals(GameSession)
	
	# act
	GameSession.display_state = GameSession.DisplayState.NONE
	
	# assert
	assert_signal_emitted_with_parameters(GameSession, "simulation_running_changed", [true])


func test_reset_leaves_the_simulation_running():
	# arrange
	GameSession.display_state = GameSession.DisplayState.QUIZ_DIALOG
	
	# act
	GameSession.reset()
	var running = GameSession.is_simulation_running()
	
	# assert
	assert_true(running)
