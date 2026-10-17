extends GutTest

func after_each():
	GameSession.difficulty_level = GameSession.DifficultyLevel.NORMAL


func test_reset():
	# arrange
	GameSession.eyes_of_ender = 5
	GameSession.has_lighter = true
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(0, GameSession.score)
	assert_eq(0, GameSession.eyes_of_ender)
	assert_false(GameSession.has_lighter)


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
