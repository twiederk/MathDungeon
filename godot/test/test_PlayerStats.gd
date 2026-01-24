extends GutTest

func test_reset():
	# arrange
	PlayerStats.has_lighter = true
	
	# act
	PlayerStats.reset()
	
	# assert
	assert_eq(5, PlayerStats.hit_points)
	assert_eq(1, PlayerStats.weapon_damage)
	assert_eq(0, PlayerStats.armor)
	assert_eq(0, PlayerStats.current_score)
	assert_false(PlayerStats.has_lighter, "Lighter should be reset")
	assert_true(PlayerStats.companion_paths.is_empty(), "Companions should be removed")
