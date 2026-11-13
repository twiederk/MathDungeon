extends GutTest

const PROC_GEN_WORLD_SCENE = preload("res://procedural/proc_gen_world.tscn")


func after_each():
	GameSession.world_seed = GameSession.NO_SEED


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
	assert_eq(speed, 100.0)


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
	GameSession.world_seed = 1234
	
	# act
	var resolved_seed = world._resolve_seed()
	
	# assert
	assert_eq(resolved_seed, 1234)


func test_resolve_seed_is_stable_across_worlds():
	# arrange
	var first_world = autofree(ProcGenWorld.new())
	var second_world = autofree(ProcGenWorld.new())
	var first_seed = first_world._resolve_seed()
	
	# act
	var second_seed = second_world._resolve_seed()
	
	# assert
	assert_eq(second_seed, first_seed)
