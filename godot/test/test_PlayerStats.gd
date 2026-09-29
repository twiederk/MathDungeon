extends GutTest

func after_each():
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.NORMAL


func test_reset():
	# arrange
	PlayerStats.eyes_of_ender = 5
	
	# act
	PlayerStats.reset()
	
	# assert
	assert_eq(0, PlayerStats.score)
	assert_eq(0, PlayerStats.eyes_of_ender)


func test_difficulty_level_default_is_normal():
	# assert
	assert_eq(PlayerStats.difficulty_level, PlayerStats.DifficultyLevel.NORMAL)
	assert_false(PlayerStats.is_hard())


func test_toggle_difficulty_level():
	# act
	PlayerStats.toggle_difficulty_level()
	
	# assert
	assert_eq(PlayerStats.difficulty_level, PlayerStats.DifficultyLevel.HARD)
	assert_true(PlayerStats.is_hard())
	
	# act
	PlayerStats.toggle_difficulty_level()
	
	# assert
	assert_eq(PlayerStats.difficulty_level, PlayerStats.DifficultyLevel.NORMAL)
	assert_false(PlayerStats.is_hard())


func test_reset_keeps_difficulty_level():
	# arrange
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.HARD
	
	# act
	PlayerStats.reset()
	
	# assert
	assert_eq(PlayerStats.difficulty_level, PlayerStats.DifficultyLevel.HARD)
