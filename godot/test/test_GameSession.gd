extends GutTest

func after_each():
	GameSession.difficulty_level = GameSession.DifficultyLevel.NORMAL
	GameSession.display_state = GameSession.DisplayState.NONE
	GameSession.overworld_path = GameSession.DEFAULT_OVERWORLD_PATH
	GameSession.world_seed = GameSession.NO_SEED
	GameSession.game_mode = GameSession.GameMode.NORMAL
	GameSession.run_duration_seconds = GameSession.RUN_DURATION_SECONDS
	GameSession.run_active = false
	GameSession.run_time_left = 0.0


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


func test_reset_restores_the_default_overworld_path():
	# arrange
	GameSession.overworld_path = "res://procedural/proc_gen_world.tscn"
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(GameSession.overworld_path, GameSession.DEFAULT_OVERWORLD_PATH)


func test_set_overworld_path():
	# arrange
	var path = "res://procedural/proc_gen_world.tscn"
	
	# act
	GameSession.set_overworld_path(path)
	
	# assert
	assert_eq(GameSession.overworld_path, path)


func test_reset_clears_the_world_seed():
	# arrange
	GameSession.world_seed = 4711
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(GameSession.world_seed, GameSession.NO_SEED)


func test_get_or_create_world_seed_creates_a_seed():
	# arrange
	GameSession.world_seed = GameSession.NO_SEED
	
	# act
	var world_seed = GameSession.get_or_create_world_seed()
	
	# assert
	assert_ne(world_seed, GameSession.NO_SEED)


func test_get_or_create_world_seed_returns_the_same_seed_twice():
	# arrange
	GameSession.world_seed = GameSession.NO_SEED
	var first_seed = GameSession.get_or_create_world_seed()
	
	# act
	var second_seed = GameSession.get_or_create_world_seed()
	
	# assert
	assert_eq(second_seed, first_seed)


func test_get_or_create_world_seed_keeps_an_existing_seed():
	# arrange
	GameSession.world_seed = 4711
	
	# act
	var world_seed = GameSession.get_or_create_world_seed()
	
	# assert
	assert_eq(world_seed, 4711)


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


func test_toggle_game_mode_switches_to_timed_run():
	# arrange
	GameSession.game_mode = GameSession.GameMode.NORMAL
	
	# act
	GameSession.toggle_game_mode()
	
	# assert
	assert_eq(GameSession.game_mode, GameSession.GameMode.TIMED_RUN)


func test_toggle_game_mode_switches_back_to_normal():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	
	# act
	GameSession.toggle_game_mode()
	
	# assert
	assert_eq(GameSession.game_mode, GameSession.GameMode.NORMAL)


func test_is_timed_run_reflects_the_game_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	
	# act
	var timed_run = GameSession.is_timed_run()
	
	# assert
	assert_true(timed_run)


func test_is_timed_run_false_in_normal_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.NORMAL
	
	# act
	var timed_run = GameSession.is_timed_run()
	
	# assert
	assert_false(timed_run)


func test_start_run_sets_the_remaining_time():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	GameSession.run_duration_seconds = 120.0
	
	# act
	GameSession.start_run()
	
	# assert
	assert_eq(GameSession.run_time_left, 120.0)


func test_start_run_activates_the_run():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	
	# act
	GameSession.start_run()
	
	# assert
	assert_true(GameSession.run_active)


func test_start_run_does_nothing_in_normal_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.NORMAL
	
	# act
	GameSession.start_run()
	
	# assert
	assert_false(GameSession.run_active)


func test_stop_run_deactivates_the_run():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	GameSession.start_run()
	
	# act
	GameSession.stop_run()
	
	# assert
	assert_false(GameSession.run_active)


func test_process_decreases_the_remaining_time():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	GameSession.start_run()
	
	# act
	GameSession._process(1.0)
	
	# assert
	assert_eq(GameSession.run_time_left, GameSession.run_duration_seconds - 1.0)


func test_process_does_not_decrease_while_a_dialog_is_shown():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	GameSession.start_run()
	GameSession.display_state = GameSession.DisplayState.QUIZ_DIALOG
	
	# act
	GameSession._process(1.0)
	
	# assert
	assert_eq(GameSession.run_time_left, GameSession.run_duration_seconds)


func test_run_time_expired_is_emitted_once_when_time_reaches_zero():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	GameSession.run_duration_seconds = 1.0
	GameSession.start_run()
	watch_signals(GameSession)
	
	# act
	GameSession._process(1.0)
	
	# assert
	assert_signal_emit_count(GameSession, "run_time_expired", 1)


func test_reset_clears_the_run_time_left():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	GameSession.start_run()
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(GameSession.run_time_left, 0.0)


func test_reset_deactivates_the_run():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	GameSession.start_run()
	
	# act
	GameSession.reset()
	
	# assert
	assert_false(GameSession.run_active)


func test_reset_keeps_the_game_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(GameSession.game_mode, GameSession.GameMode.TIMED_RUN)
