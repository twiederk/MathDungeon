extends GutTest

func after_each():
	GameSession.difficulty_level = GameSession.DifficultyLevel.NORMAL
	GameSession.display_state = GameSession.DisplayState.NONE
	GameSession.world_seed = GameSession.NO_SEED
	GameSession.game_mode = GameSession.GameMode.NORMAL
	GameSession.run_duration_seconds = GameSession.RUN_DURATION_SECONDS
	GameSession.run_active = false
	GameSession.run_time_left = 0.0
	GameSession.procedural_game_session.reset_procedural_progression()


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


func test_start_procedural_run_creates_the_first_level_configuration():
	# arrange
	GameSession.procedural_game_session.get_or_create_procedural_level_config(3)
	GameSession.procedural_game_session.procedural_level = 3

	# act
	var level_config = GameSession.start_procedural_run()

	# assert
	assert_eq(GameSession.procedural_game_session.procedural_level, ProceduralGameSession.FIRST_PROCEDURAL_LEVEL)
	assert_eq(GameSession.procedural_game_session.procedural_level_configs.size(), 1)
	assert_true(level_config is LevelConfig)
	assert_eq(level_config.size, ProceduralGameSession.FIRST_PROCEDURAL_LEVEL_SIZE)
	assert_eq(level_config.splits, ProceduralGameSession.FIRST_PROCEDURAL_LEVEL_SPLITS)
	assert_ne(level_config.seed_value, GameSession.NO_SEED)


func test_procedural_level_configuration_is_stable_when_requested_again():
	# arrange
	var first_config = GameSession.procedural_game_session.get_or_create_procedural_level_config(2)

	# act
	var second_config = GameSession.procedural_game_session.get_or_create_procedural_level_config(2)

	# assert
	assert_eq(second_config.seed_value, first_config.seed_value)
	assert_eq(second_config.size, first_config.size)
	assert_eq(second_config.splits, first_config.splits)
	assert_eq(second_config.level, 2)
	assert_ne(second_config, first_config)
	assert_eq(GameSession.procedural_game_session.procedural_level_configs.size(), 1)


func test_returned_procedural_level_configuration_does_not_change_the_cached_configuration():
	# arrange
	var first_config = GameSession.procedural_game_session.get_or_create_procedural_level_config(1)
	var original_seed = first_config.seed_value
	first_config.seed_value = GameSession.NO_SEED
	first_config.size = Vector2i.ONE
	first_config.splits = 0
	first_config.level = 99

	# act
	var second_config = GameSession.procedural_game_session.get_or_create_procedural_level_config(1)

	# assert
	assert_eq(second_config.seed_value, original_seed)
	assert_eq(second_config.size, ProceduralGameSession.FIRST_PROCEDURAL_LEVEL_SIZE)
	assert_eq(second_config.splits, ProceduralGameSession.FIRST_PROCEDURAL_LEVEL_SPLITS)
	assert_eq(second_config.level, 1)


func test_procedural_level_configuration_stores_requested_level_index(parameters = use_parameters([
	[1],
	[2],
	[3],
	[4],
	[5],
	[6],
	[7],
	[1000],
])):
	var level_index = parameters[0]

	# act
	var level_config = GameSession.get_or_create_procedural_level_config(level_index)

	# assert
	assert_eq(level_config.level, level_index)


func test_procedural_level_progression(parameters = use_parameters([
	[1, Vector2i(39, 22), 3],
	[2, Vector2i(39, 22), 3],
	[3, Vector2i(44, 27), 3],
	[4, Vector2i(44, 27), 3],
	[7, Vector2i(54, 37), 3],
	[8, Vector2i(54, 37), 3],
	[9, Vector2i(59, 42), 3],
	[10, Vector2i(59, 42), 3],
	[23, Vector2i(94, 77), 4],
	[24, Vector2i(94, 77), 4],
	[25, Vector2i(99, 82), 4],
	[26, Vector2i(99, 82), 4],
	[31, Vector2i(114, 97), 5],
	[32, Vector2i(114, 97), 5],
	[33, Vector2i(119, 102), 5],
	[34, Vector2i(119, 102), 5],
	[39, Vector2i(120, 117), 5],
	[40, Vector2i(120, 117), 5],
	[41, Vector2i(120, 120), 5],
	[42, Vector2i(120, 120), 5],
	[1000, Vector2i(120, 120), 5],
	[9223372036854775807, Vector2i(120, 120), 5]
])):
	# arrange
	var level_index = parameters[0]
	var expected_size = parameters[1]
	var expected_splits = parameters[2]

	# act
	var level_config = GameSession.get_or_create_procedural_level_config(level_index)

	# assert
	assert_eq(level_config.size, expected_size)
	assert_eq(level_config.splits, expected_splits)
	assert_eq(level_config.level, level_index)
	assert_ne(level_config.seed_value, GameSession.NO_SEED)


func test_procedural_split_thresholds_require_both_dimensions(parameters = use_parameters([
	[Vector2i(40, 23), 3],
	[Vector2i(59, 40), 3],
	[Vector2i(60, 39), 3],
	[Vector2i(60, 40), 4],
	[Vector2i(99, 80), 4],
	[Vector2i(100, 79), 4],
	[Vector2i(100, 80), 5],
	[Vector2i(120, 120), 5]
])):
	# arrange
	var level_size = parameters[0]
	var expected_splits = parameters[1]

	# act
	var splits = GameSession.procedural_game_session._get_splits_for_size(level_size)

	# assert
	assert_eq(splits, expected_splits)


func test_capped_procedural_levels_keep_separate_cached_configurations():
	# arrange
	var first_config = GameSession.get_or_create_procedural_level_config(41)
	var deeper_config = GameSession.get_or_create_procedural_level_config(43)

	# act
	var revisited_config = GameSession.get_or_create_procedural_level_config(41)

	# assert
	assert_eq(deeper_config.size, first_config.size)
	assert_eq(deeper_config.splits, first_config.splits)
	assert_eq(revisited_config.seed_value, first_config.seed_value)
	assert_ne(deeper_config, first_config)
	assert_eq(GameSession.procedural_game_session.procedural_level_configs.size(), 2)


func test_procedural_clear_bonus_uses_bounded_split_tiers(parameters = use_parameters([
	[-1, 500],
	[3, 500],
	[4, 1000],
	[5, 2000],
	[9223372036854775807, 2000]
])):
	# arrange
	var splits: int = parameters[0]
	var expected_bonus: int = parameters[1]

	# act
	var bonus = GameSession.get_procedural_clear_bonus(splits)

	# assert
	assert_eq(bonus, expected_bonus)


func test_reset_clears_procedural_level_configurations():
	# arrange
	GameSession.procedural_game_session.start_procedural_run()
	GameSession.procedural_game_session.get_or_create_procedural_level_config(2)
	GameSession.procedural_game_session.procedural_level = 2

	# act
	GameSession.reset()

	# assert
	assert_eq(GameSession.procedural_game_session.procedural_level, ProceduralGameSession.FIRST_PROCEDURAL_LEVEL)
	assert_true(GameSession.procedural_game_session.procedural_level_configs.is_empty())


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
