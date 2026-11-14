extends GutTest

const PROC_GEN_WORLD_SCENE = preload("res://procedural/proc_gen_world.tscn")


func after_each():
	GameSession.world_seed = GameSession.NO_SEED
	GameSession.reset_procedural_progression()


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
	GameSession.procedural_level_configs[1] = {"seed": 1234, "size": Vector2i(80, 80), "splits": 3}
	
	# act
	var resolved_seed = world._resolve_seed()
	
	# assert
	assert_eq(resolved_seed, 1234)


func test_resolve_level_config_uses_the_session_level_size():
	# arrange
	var world = autofree(ProcGenWorld.new())
	var size := Vector2i(60, 60)
	GameSession.procedural_level_configs[1] = {"seed": 1234, "size": size, "splits": 3}

	# act
	var level_config = world._resolve_level_config()

	# assert
	assert_eq(level_config["size"], size)
	assert_eq(level_config["seed"], 1234)
	assert_eq(level_config["splits"], 3)


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
	GameSession.procedural_level_configs[1] = {"seed": 1234, "size": size, "splits": 4}

	# act
	var world = add_child_autofree(PROC_GEN_WORLD_SCENE.instantiate())

	# assert
	assert_eq(world.dungeon.root_node.size, size)
	assert_eq(_branch_depth(world.dungeon.root_node), 5)


func test_world_places_stairs_at_dungeon_endpoints():
	# arrange
	GameSession.procedural_level_configs[1] = {"seed": 1234, "size": Vector2i(60, 60), "splits": 3}

	# act
	var world = add_child_autofree(PROC_GEN_WORLD_SCENE.instantiate())

	# assert
	var stairs_up = world.get_node("Locations/StairsUp")
	var stairs_down = world.get_node("Locations/StairsDown")
	var expected_up_position = world.tile_map_layer.to_global(world.tile_map_layer.map_to_local(world.dungeon.start_position))
	var expected_down_position = world.tile_map_layer.to_global(world.tile_map_layer.map_to_local(world.dungeon.end_position))
	assert_eq(stairs_up.global_position, expected_up_position)
	assert_eq(stairs_down.global_position, expected_down_position)


func test_descending_creates_and_enters_next_level():
	# arrange
	var world = autofree(ProcGenWorld.new())

	# act
	var should_end_run = world._handle_stair_transition(true)

	# assert
	assert_false(should_end_run)
	assert_eq(GameSession.procedural_level_index, 2)
	assert_false(GameSession.procedural_spawn_at_end)
	assert_true(GameSession.procedural_level_configs.has(2))


func test_ascending_returns_to_previous_level_at_down_stairs():
	# arrange
	var world = autofree(ProcGenWorld.new())
	GameSession.procedural_level_index = 2
	GameSession.get_or_create_procedural_level_config(2)

	# act
	var should_end_run = world._handle_stair_transition(false)

	# assert
	assert_false(should_end_run)
	assert_eq(GameSession.procedural_level_index, 1)
	assert_true(GameSession.procedural_spawn_at_end)


func test_arriving_from_below_spawns_at_last_room():
	# arrange
	GameSession.procedural_spawn_at_end = true
	GameSession.procedural_level_configs[1] = {"seed": 1234, "size": Vector2i(60, 60), "splits": 3}

	# act
	var world = add_child_autofree(PROC_GEN_WORLD_SCENE.instantiate())

	# assert
	var expected_position = world.tile_map_layer.to_global(world.tile_map_layer.map_to_local(world.dungeon.end_position))
	assert_eq(world.player.global_position, expected_position)
	assert_false(world.get_node("Locations/StairsDown").is_armed())


func test_arriving_from_above_spawns_at_first_room():
	# arrange
	GameSession.procedural_spawn_at_end = false
	GameSession.procedural_level_configs[1] = {"seed": 1234, "size": Vector2i(60, 60), "splits": 3}

	# act
	var world = add_child_autofree(PROC_GEN_WORLD_SCENE.instantiate())

	# assert
	var expected_position = world.tile_map_layer.to_global(world.tile_map_layer.map_to_local(world.dungeon.start_position))
	assert_eq(world.player.global_position, expected_position)
	assert_false(world.get_node("Locations/StairsUp").is_armed())


func test_arrival_stairs_arm_after_player_exits():
	# arrange
	GameSession.procedural_spawn_at_end = true
	GameSession.procedural_level_configs[1] = {"seed": 1234, "size": Vector2i(60, 60), "splits": 3}
	var world = add_child_autofree(PROC_GEN_WORLD_SCENE.instantiate())
	var stairs_down = world.get_node("Locations/StairsDown")

	# act
	stairs_down._on_body_exited(world.player)

	# assert
	assert_true(stairs_down.is_armed())


func test_first_level_up_stairs_end_the_run():
	# arrange
	var world = autofree(ProcGenWorld.new())

	# act
	var should_end_run = world._handle_stair_transition(false)

	# assert
	assert_true(should_end_run)
	assert_eq(GameSession.procedural_level_index, GameSession.FIRST_PROCEDURAL_LEVEL)


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
