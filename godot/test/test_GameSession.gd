extends GutTest

func after_each():
	GameSession.difficulty_level = GameSession.DifficultyLevel.NORMAL


func test_reset():
	# arrange
	GameSession.eyes_of_ender = 5
	
	# act
	GameSession.reset()
	
	# assert
	assert_eq(0, GameSession.score)
	assert_eq(0, GameSession.eyes_of_ender)


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
