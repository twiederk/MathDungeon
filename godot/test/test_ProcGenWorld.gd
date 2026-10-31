extends GutTest


func after_each():
	GameSession.world_seed = GameSession.NO_SEED


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
