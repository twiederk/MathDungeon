extends GutTest

const PROC_GEN_WORLD_SCENE = preload("res://procedural/proc_gen_world.tscn")


class WorldWithoutAutoGeneration:
	extends ProcGenWorld

	func _ready() -> void:
		pass


func after_each():
	GameSession.world_seed = GameSession.NO_SEED
	GameSession.procedural_game_session.reset_procedural_progression()
	AchievementManager.clear_locations()


func test_get_world_title_uses_current_level(parameters = use_parameters([
	[1, "Ebene 1"],
	[2, "Ebene 2"]
])):
	# arrange
	var world = autofree(ProcGenWorld.new())
	world.world_title = "Ignored authored title"
	GameSession.set_procedural_level_index(parameters[0])

	# act
	var title = world._get_world_title()

	# assert
	assert_eq(title, parameters[1])


func test_get_world_title_updates_when_returning_to_first_level():
	# arrange
	var world = autofree(ProcGenWorld.new())
	GameSession.set_procedural_level_index(2)
	GameSession.set_procedural_level_index(1)

	# act
	var title = world._get_world_title()

	# assert
	assert_eq(title, "Ebene 1")


func test_player_default_speed_is_unchanged():
	# arrange
	var player = autofree(Player.new())

	# act
	var speed = player._speed()

	# assert
	assert_eq(speed, 200.0)


func test_world_player_uses_reduced_speed():
	# arrange
	var world = autofree(PROC_GEN_WORLD_SCENE.instantiate())
	var player = world.get_node("Player")

	# act
	var speed = player._speed()

	# assert
	assert_eq(speed, 120.0)


func test_resolve_seed_prefers_the_exported_seed():
	# arrange
	var world = autofree(ProcGenWorld.new())
	world.seed_value = 4711
	GameSession.world_seed = 1234
	
	# act
	var resolved_seed = world._resolve_seed()
	
	# assert
	assert_eq(resolved_seed, 4711)


func test_resolve_seed_uses_the_session_seed():
	# arrange
	var world = autofree(ProcGenWorld.new())
	world.seed_value = GameSession.NO_SEED
	GameSession.procedural_game_session.procedural_level_configs[1] = LevelConfig.new(1234, Vector2i(80, 80), 3)
	
	# act
	var resolved_seed = world._resolve_seed()
	
	# assert
	assert_eq(resolved_seed, 1234)


func test_resolve_level_config_uses_the_session_level_size():
	# arrange
	var world = autofree(ProcGenWorld.new())
	var size := Vector2i(60, 60)
	GameSession.procedural_game_session.procedural_level_configs[1] = LevelConfig.new(1234, size, 3)

	# act
	var level_config = world._resolve_level_config()

	# assert
	assert_eq(level_config.size, size)
	assert_eq(level_config.seed_value, 1234)
	assert_eq(level_config.splits, 3)


func test_resolve_level_config_seed_override_does_not_change_the_session_configuration():
	var world = autofree(ProcGenWorld.new())
	world.seed_value = 4711
	GameSession.procedural_game_session.procedural_level_configs[1] = LevelConfig.new(1234, Vector2i(60, 60), 3)

	var level_config = world._resolve_level_config()

	assert_eq(level_config.seed_value, 4711)
	assert_eq(GameSession.procedural_game_session.procedural_level_configs[1].seed_value, 1234)


func test_resolve_seed_is_stable_across_worlds():
	# arrange
	var first_world = autofree(ProcGenWorld.new())
	var second_world = autofree(ProcGenWorld.new())
	var first_seed = first_world._resolve_seed()
	
	# act
	var second_seed = second_world._resolve_seed()
	
	# assert
	assert_eq(second_seed, first_seed)


func test_world_generation_uses_the_session_level_size():
	# arrange
	var size := Vector2i(60, 60)
	GameSession.procedural_game_session.procedural_level_configs[1] = LevelConfig.new(1234, size, 4)
	var world = _create_world_for_generation()
	var level_config = world._resolve_level_config()

	# act
	world.generate_world(level_config)

	# assert
	assert_eq(world.dungeon.root_node.size, size)
	assert_eq(_branch_depth(world.dungeon.root_node), 5)


func test_world_places_stairs_at_dungeon_endpoints():
	# arrange
	GameSession.procedural_game_session.procedural_level_configs[1] = LevelConfig.new(1234, Vector2i(60, 60), 3)
	var world = _create_world_for_generation()
	var level_config = world._resolve_level_config()

	# act
	world.generate_world(level_config)

	# assert
	var stairs_up = world.get_node("Locations/StairsUp")
	var stairs_down = world.get_node("Locations/StairsDown")
	var expected_up_position = world.tile_map_layer.to_global(world.tile_map_layer.map_to_local(world.dungeon.start_position))
	var expected_down_position = world.tile_map_layer.to_global(world.tile_map_layer.map_to_local(world.dungeon.end_position))
	assert_eq(stairs_up.global_position, expected_up_position)
	assert_eq(stairs_down.global_position, expected_down_position)


func test_world_uses_progression_size_and_splits(parameters = use_parameters([
	[1, Vector2i(40, 23), 3, ProcGenWorld.SAND_TERRAIN_ID],
	[2, Vector2i(40, 23), 3, ProcGenWorld.DIRT_TERRAIN_ID],
	[3, Vector2i(45, 28), 3, ProcGenWorld.SAND_TERRAIN_ID]
])):
	# arrange
	var expected_size = parameters[1]
	var expected_depth = parameters[2] + 1
	GameSession.set_procedural_level_index(parameters[0])
	var world = _create_world_for_generation()
	world.seed_value = 4711
	var level_config = world._resolve_level_config()

	# act
	world.generate_world(level_config)

	# assert
	assert_eq(world.dungeon.root_node.size, expected_size)
	assert_eq(_branch_depth(world.dungeon.root_node), expected_depth)
	assert_ne(world.stairs_up.global_position, world.stairs_down.global_position)
	assert_eq(world.player.global_position, world.stairs_up.global_position)
	assert_has(world.dungeon.floor_arr, world.dungeon.stairs_up_position)
	assert_has(world.dungeon.floor_arr, world.dungeon.stairs_down_position)
	var floor_tile_data = world.tile_map_layer.get_cell_tile_data(world.dungeon.stairs_up_position)
	assert_not_null(floor_tile_data)
	if floor_tile_data != null:
		assert_eq(floor_tile_data.terrain, parameters[3])
	assert_eq(world.dungeon.id, "dungeon_procedural")
	assert_gt(world.dungeon.enemies.size(), 0)
	for enemy in world.dungeon.enemies:
		assert_eq(enemy.location, world.dungeon.id)


func test_location_setup_uses_the_generated_visit_bonus():
	# arrange
	var world = _create_world_for_generation()
	var level_config = LevelConfig.new(4711, Vector2i(40, 23), 4)
	world.generate_world(level_config)
	GameSession.set_procedural_level_index(41)

	# act
	world._setup_locations()

	# assert
	assert_eq(world.dungeon.id, "dungeon_procedural")
	assert_eq(AchievementManager._locations[world.dungeon.id].remaining_enemies.size(), world.dungeon.enemies.size())
	assert_eq(AchievementManager._locations[world.dungeon.id].bonus, 1000)


func _create_world_for_generation() -> ProcGenWorld:
	var world = PROC_GEN_WORLD_SCENE.instantiate()
	world.set_script(WorldWithoutAutoGeneration)
	return add_child_autofree(world)


func test_descending_creates_and_enters_next_level():
	# arrange
	var world = autofree(ProcGenWorld.new())

	# act
	var should_end_run = world._handle_stair_transition(true)

	# assert
	assert_false(should_end_run)
	assert_eq(GameSession.procedural_game_session.procedural_level_index, 2)
	assert_false(GameSession.procedural_game_session.procedural_spawn_at_end)
	assert_true(GameSession.procedural_game_session.procedural_level_configs.has(2))


func test_ascending_returns_to_previous_level_at_down_stairs():
	# arrange
	var world = autofree(ProcGenWorld.new())
	GameSession.procedural_game_session.procedural_level_index = 2
	GameSession.procedural_game_session.get_or_create_procedural_level_config(2)

	# act
	var should_end_run = world._handle_stair_transition(false)

	# assert
	assert_false(should_end_run)
	assert_eq(GameSession.procedural_game_session.procedural_level_index, 1)
	assert_true(GameSession.procedural_game_session.procedural_spawn_at_end)


func test_arriving_from_below_spawns_at_last_room():
	# arrange
	GameSession.procedural_game_session.procedural_spawn_at_end = true
	GameSession.procedural_game_session.procedural_level_configs[1] = LevelConfig.new(1234, Vector2i(60, 60), 3)
	var world = add_child_autofree(PROC_GEN_WORLD_SCENE.instantiate())
	world.player.global_position = Vector2.ZERO

	# act
	world._place_player()

	# assert
	assert_eq(world.player.global_position, world.stairs_down.global_position)


func test_arriving_from_above_spawns_at_first_room():
	# arrange
	GameSession.procedural_game_session.procedural_spawn_at_end = false
	GameSession.procedural_game_session.procedural_level_configs[1] = LevelConfig.new(1234, Vector2i(60, 60), 3)
	var world = add_child_autofree(PROC_GEN_WORLD_SCENE.instantiate())
	world.player.global_position = Vector2.ZERO

	# act
	world._place_player()

	# assert
	assert_eq(world.player.global_position, world.stairs_up.global_position)


func test_spawn_stair_ignores_initial_player_entry():
	# arrange
	var stairs = autofree(ProceduralStairs.new())
	var player = autofree(Player.new())
	player.name = "Player"
	stairs.place_player(player)
	watch_signals(stairs)

	# act
	stairs._on_body_entered(player)

	# assert
	assert_signal_not_emitted(stairs, "activated")
	assert_eq(player.global_position, stairs.global_position)


func test_spawn_stair_activates_after_player_leaves_and_reenters():
	# arrange
	var stairs = autofree(ProceduralStairs.new())
	var player = autofree(Player.new())
	player.name = "Player"
	stairs.place_player(player)
	stairs._on_body_exited(player)
	watch_signals(stairs)

	# act
	stairs._on_body_entered(player)

	# assert
	assert_signal_emitted_with_parameters(stairs, "activated", [false])


func test_first_level_up_stairs_end_the_run():
	# arrange
	var world = autofree(ProcGenWorld.new())

	# act
	var should_end_run = world._handle_stair_transition(false)

	# assert
	assert_true(should_end_run)
	assert_eq(GameSession.procedural_game_session.procedural_level_index, ProceduralGameSession.FIRST_PROCEDURAL_LEVEL)


func test_procedural_run_end_routes_by_highscore_eligibility():
	# arrange
	var world = autofree(ProcGenWorld.new())

	# act
	var destinations = _get_run_end_destinations(world)

	# assert
	assert_eq(destinations["highscore"], world.NAME_ENTRY_DIALOG_PATH)
	assert_eq(destinations["menu"], "res://gui/start_gui.tscn")


func _get_run_end_destinations(world: ProcGenWorld) -> Dictionary:
	return {
		"highscore": world._resolve_procedural_run_end_scene(true),
		"menu": world._resolve_procedural_run_end_scene(false)
	}


func _branch_depth(branch: Branch) -> int:
	if branch.is_leaf():
		return 0
	return 1 + max(_branch_depth(branch.left_child), _branch_depth(branch.right_child))
