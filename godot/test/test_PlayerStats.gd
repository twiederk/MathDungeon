extends GutTest

func test_reset():
	
	# act
	PlayerStats.reset()
	
	# assert
	assert_eq(5, PlayerStats.hit_points)
	assert_eq(1, PlayerStats.weapon_damage)
	assert_eq(0, PlayerStats.armor)
	assert_eq(0, PlayerStats.current_score)
	assert_true(PlayerStats.companion_paths.is_empty())
