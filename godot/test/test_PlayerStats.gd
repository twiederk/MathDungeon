extends GutTest

func test_reset():
	# arrange
	PlayerStats.eyes_of_ender = 5
	
	# act
	PlayerStats.reset()
	
	# assert
	assert_eq(0, PlayerStats.score)
	assert_eq(0, PlayerStats.eyes_of_ender)
