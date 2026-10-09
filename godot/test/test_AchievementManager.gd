extends GutTest


func after_each():
	AchievementManager.reset()


func test_location_achievements_have_bonus_points():
	# assert
	assert_eq(500, AchievementManager.ACHIEVEMENTS["dungeon_0"].bonus)
	assert_eq(500, AchievementManager.ACHIEVEMENTS["dungeon_1"].bonus)
	assert_eq(500, AchievementManager.ACHIEVEMENTS["dungeon_2"].bonus)
	assert_eq(500, AchievementManager.ACHIEVEMENTS["dungeon_3"].bonus)
	assert_eq(1000, AchievementManager.ACHIEVEMENTS["woodland_mansion"].bonus)
	assert_eq(1500, AchievementManager.ACHIEVEMENTS["nether_fortress"].bonus)


func test_other_achievements_have_no_bonus_points():
	# assert
	assert_eq(0, AchievementManager.ACHIEVEMENTS["score_1000"].bonus)
	assert_eq(0, AchievementManager.ACHIEVEMENTS["enderman_1"].bonus)
	assert_eq(0, AchievementManager.ACHIEVEMENTS["enderdragon_1"].bonus)
	assert_eq(0, AchievementManager.ACHIEVEMENTS["nether_1"].bonus)


func test_register_locations_counts_enemies_per_location():
	# arrange
	var enemies = [_create_enemy("dungeon_0"), _create_enemy("dungeon_0"), _create_enemy("dungeon_1")]
	
	# act
	AchievementManager.register_locations(enemies)
	
	# assert
	assert_eq(2, AchievementManager._locations["dungeon_0"])
	assert_eq(1, AchievementManager._locations["dungeon_1"])


func test_register_locations_ignores_enemies_without_location():
	# arrange
	var enemies = [_create_enemy(""), _create_enemy("dungeon_0")]
	
	# act
	AchievementManager.register_locations(enemies)
	
	# assert
	assert_false(AchievementManager._locations.has(""))
	assert_eq(1, AchievementManager._locations["dungeon_0"])


func test_clear_locations_resets_counts():
	# arrange
	var enemies = [_create_enemy("dungeon_0")]
	AchievementManager.register_locations(enemies)
	
	# act
	AchievementManager.clear_locations()
	
	# assert
	assert_true(AchievementManager._locations.is_empty())


func test_last_defeat_unlocks_achievement():
	# arrange
	var enemy = _create_enemy("dungeon_0")
	AchievementManager.register_locations([enemy])
	watch_signals(AchievementManager)
	
	# act
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_signal_emitted(AchievementManager, "achievement_unlocked")
	assert_true("dungeon_0" in AchievementManager.unlocked_achievements)


func test_defeat_before_last_does_not_unlock():
	# arrange
	var enemies = [_create_enemy("dungeon_0"), _create_enemy("dungeon_0")]
	AchievementManager.register_locations(enemies)
	watch_signals(AchievementManager)
	
	# act
	AchievementManager.track_enemy_defeat(enemies[0])
	
	# assert
	assert_signal_not_emitted(AchievementManager, "achievement_unlocked")
	assert_eq(1, AchievementManager._locations["dungeon_0"])


func test_defeat_of_unregistered_location_is_ignored():
	# arrange
	var enemy = _create_enemy("dungeon_0")
	watch_signals(AchievementManager)
	
	# act
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_signal_not_emitted(AchievementManager, "achievement_unlocked")
	assert_eq(0, AchievementManager._locations.size())


func _create_enemy(location: String) -> Enemy:
	var enemy = autofree(Enemy.new())
	enemy.stats = EnemyStats.new()
	enemy.location = location
	return enemy
