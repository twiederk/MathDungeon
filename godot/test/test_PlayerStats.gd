extends GutTest

func test_reset():
	# arrange
	PlayerStats.has_lighter = true
	PlayerStats.eyes_of_ender = 5
	
	# act
	PlayerStats.reset()
	
	# assert
	assert_eq(5, PlayerStats.hit_points)
	assert_eq(1, PlayerStats.weapon_damage)
	assert_eq(0, PlayerStats.armor)
	assert_eq(0, PlayerStats.score)
	assert_eq(0, PlayerStats.eyes_of_ender)
	assert_false(PlayerStats.has_lighter, "Lighter should be reset")
	assert_true(PlayerStats.companion_paths.is_empty(), "Companions should be removed")


func test_needs_healing_true():
	# arrange
	PlayerStats.max_hit_points = 5
	PlayerStats.hit_points = 4
	
	# act
	var result = PlayerStats.needs_healing()
	
	# assert
	assert_true(result, "Player need healing if hit points are lower than max hit points")




func test_needs_healing_false():
	# arrange
	PlayerStats.max_hit_points = 5
	PlayerStats.hit_points = 5
	
	# act
	var result = PlayerStats.needs_healing()
	
	# assert
	assert_false(result, "Player doesn't need healing if hit points are equal to max hit points")
