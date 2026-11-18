extends GutTest


func after_each():
	AchievementManager.reset()
	GameSession.reset()
	CharacterManager.current.inventory.goods.clear()


func test_location_achievements_have_bonus_points():
	# assert
	assert_eq(500, AchievementManager.ACHIEVEMENTS["dungeon"].bonus)
	assert_eq(1000, AchievementManager.ACHIEVEMENTS["woodland_mansion"].bonus)
	assert_eq(1500, AchievementManager.ACHIEVEMENTS["nether_fortress"].bonus)


func test_item_achievements_have_bonus_points():
	# assert
	assert_eq(250, AchievementManager.ACHIEVEMENTS["lighter"].bonus)
	assert_eq(1000, AchievementManager.ACHIEVEMENTS["eyes_12"].bonus)


func test_collecting_eyes_of_ender_unlocks_achievement():
	# act
	for i in 4:
		CharacterManager.current.equip_good(_create_good("eye_of_ender"))
	
	# assert
	assert_true("eyes_4" in AchievementManager.unlocked_achievements)
	assert_false("eyes_8" in AchievementManager.unlocked_achievements)


func test_twelve_eyes_of_ender_unlock_all_eye_achievements():
	# act
	for i in 12:
		CharacterManager.current.equip_good(_create_good("eye_of_ender"))
	
	# assert
	assert_true("eyes_4" in AchievementManager.unlocked_achievements)
	assert_true("eyes_8" in AchievementManager.unlocked_achievements)
	assert_true("eyes_12" in AchievementManager.unlocked_achievements)


func test_picking_up_lighter_unlocks_achievement():
	# act
	CharacterManager.current.equip_good(_create_good("lighter"))
	
	# assert
	assert_true("lighter" in AchievementManager.unlocked_achievements)


func test_lighter_is_not_unlocked_without_pickup():
	# assert
	assert_false("lighter" in AchievementManager.unlocked_achievements)


func test_register_locations_counts_enemies_per_location():
	# arrange
	var enemies = [_create_enemy("dungeon_0"), _create_enemy("dungeon_0"), _create_enemy("dungeon_1")]
	
	# act
	AchievementManager.register_locations(enemies)
	
	# assert
	assert_eq(2, AchievementManager._locations["dungeon_0"].remaining_enemies.size())
	assert_eq(1, AchievementManager._locations["dungeon_1"].remaining_enemies.size())


func test_register_locations_ignores_enemies_without_location():
	# arrange
	var enemies = [_create_enemy(""), _create_enemy("dungeon_0")]
	
	# act
	AchievementManager.register_locations(enemies)
	
	# assert
	assert_false(AchievementManager._locations.has(""))
	assert_eq(1, AchievementManager._locations["dungeon_0"].remaining_enemies.size())


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
	assert_true("dungeon" in AchievementManager.unlocked_achievements)


func test_every_dungeon_unlocks_the_same_achievement():
	# arrange
	var first = _create_enemy("dungeon_0")
	var second = _create_enemy("dungeon_1")
	AchievementManager.register_locations([first, second])
	AchievementManager.track_enemy_defeat(first)
	
	# act
	AchievementManager.track_enemy_defeat(second)
	
	# assert
	assert_eq(2, AchievementManager.progress["dungeon"])
	assert_eq(1000, GameSession.score, "Every cleared dungeon awards the bonus again")


func test_clearing_the_same_dungeon_again_awards_the_bonus_again():
	# arrange
	var enemy = _create_enemy("dungeon_0")
	AchievementManager.register_locations([enemy])
	AchievementManager.track_enemy_defeat(enemy)
	
	# act
	AchievementManager.register_locations([enemy])
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_eq(1000, GameSession.score)


func test_clearing_woodland_mansion_again_does_not_award_the_bonus_again():
	# arrange
	var enemy = _create_enemy("woodland_mansion")
	AchievementManager.register_locations([enemy])
	AchievementManager.track_enemy_defeat(enemy)
	
	# act
	AchievementManager.register_locations([enemy])
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_eq(1000, GameSession.score)


func test_defeat_before_last_does_not_unlock():
	# arrange
	var enemies = [_create_enemy("dungeon_0"), _create_enemy("dungeon_0")]
	AchievementManager.register_locations(enemies)
	watch_signals(AchievementManager)
	
	# act
	AchievementManager.track_enemy_defeat(enemies[0])
	
	# assert
	assert_signal_not_emitted(AchievementManager, "achievement_unlocked")
	assert_eq(1, AchievementManager._locations["dungeon_0"].remaining_enemies.size())


func test_defeat_of_unregistered_location_is_ignored():
	# arrange
	var enemy = _create_enemy("dungeon_0")
	watch_signals(AchievementManager)
	
	# act
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_signal_not_emitted(AchievementManager, "achievement_unlocked")
	assert_eq(0, AchievementManager._locations.size())


func test_clearing_dungeon_awards_bonus_score():
	# arrange
	var enemy = _create_enemy("dungeon_0")
	AchievementManager.register_locations([enemy])
	
	# act
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_eq(500, GameSession.score)


func test_clearing_woodland_mansion_awards_bonus_score():
	# arrange
	var enemy = _create_enemy("woodland_mansion")
	AchievementManager.register_locations([enemy])
	
	# act
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_eq(1000, GameSession.score)


func test_clearing_nether_fortress_awards_bonus_score():
	# arrange
	var enemy = _create_enemy("nether_fortress")
	AchievementManager.register_locations([enemy])
	
	# act
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_eq(1500, GameSession.score)


func test_defeat_after_location_is_cleared_is_ignored():
	# arrange
	var enemy = _create_enemy("dungeon_0")
	AchievementManager.register_locations([enemy])
	AchievementManager.track_enemy_defeat(enemy)
	
	# act
	AchievementManager.track_enemy_defeat(enemy)
	
	# assert
	assert_eq(500, GameSession.score)


func test_procedural_clear_awards_selected_bonus(parameters = use_parameters([500, 1000, 2000])):
	# arrange
	var enemy = _create_enemy("dungeon_procedural_1")
	var expected_bonus: int = parameters
	AchievementManager.register_locations([enemy])
	AchievementManager.register_location_bonus(enemy.location, expected_bonus)

	# act
	AchievementManager.track_enemy_defeat(enemy)

	# assert
	assert_eq(GameSession.score, expected_bonus)
	assert_eq(AchievementManager.progress["dungeon"], 1)
	assert_has(AchievementManager.unlocked_achievements, "dungeon")
	assert_eq(AchievementManager.ACHIEVEMENTS["dungeon"].bonus, 500)


func test_duplicate_defeat_does_not_clear_a_multi_enemy_dungeon():
	# arrange
	var first_enemy = _create_enemy("dungeon_procedural_1")
	var last_enemy = _create_enemy("dungeon_procedural_1")
	AchievementManager.register_locations([first_enemy, last_enemy])
	AchievementManager.register_location_bonus(first_enemy.location, 1000)
	AchievementManager.track_enemy_defeat(first_enemy)

	# act
	AchievementManager.track_enemy_defeat(first_enemy)

	# assert
	assert_eq(AchievementManager._locations[first_enemy.location].remaining_enemies.size(), 1)
	assert_eq(AchievementManager.progress["dungeon"], 0)
	assert_eq(GameSession.score, 0)


func test_unregistered_enemy_cannot_clear_a_registered_location():
	# arrange
	var registered_enemy = _create_enemy("dungeon_procedural_1")
	var unregistered_enemy = _create_enemy(registered_enemy.location)
	AchievementManager.register_locations([registered_enemy])
	AchievementManager.register_location_bonus(registered_enemy.location, 2000)

	# act
	AchievementManager.track_enemy_defeat(unregistered_enemy)

	# assert
	assert_eq(AchievementManager._locations[registered_enemy.location].remaining_enemies.size(), 1)
	assert_eq(GameSession.score, 0)


func test_procedural_clear_bonus_is_not_awarded_twice_per_visit():
	# arrange
	var enemy = _create_enemy("dungeon_procedural_1")
	AchievementManager.register_locations([enemy])
	AchievementManager.register_location_bonus(enemy.location, 2000)
	AchievementManager.track_enemy_defeat(enemy)

	# act
	AchievementManager.track_enemy_defeat(enemy)

	# assert
	assert_eq(GameSession.score, 2000)
	assert_eq(AchievementManager.progress["dungeon"], 1)


func test_regenerated_visit_can_award_another_procedural_bonus():
	# arrange
	var first_enemy = _create_enemy("dungeon_procedural")
	var regenerated_first = _create_enemy(first_enemy.location)
	var regenerated_last = _create_enemy(first_enemy.location)
	AchievementManager.register_locations([first_enemy])
	AchievementManager.register_location_bonus(first_enemy.location, 1000)
	AchievementManager.track_enemy_defeat(first_enemy)
	AchievementManager.clear_locations()
	AchievementManager.register_locations([regenerated_first, regenerated_last])
	AchievementManager.register_location_bonus(first_enemy.location, 1000)
	AchievementManager.track_enemy_defeat(regenerated_first)

	# act
	AchievementManager.track_enemy_defeat(regenerated_last)

	# assert
	assert_eq(GameSession.score, 2000)
	assert_eq(AchievementManager.progress["dungeon"], 2)
	assert_eq(AchievementManager.recent_unlocks, ["dungeon", "dungeon"])


func test_location_clear_discards_partial_population_and_bonus():
	# arrange
	var first_enemy = _create_enemy("dungeon_procedural_1")
	var last_enemy = _create_enemy(first_enemy.location)
	AchievementManager.register_locations([first_enemy, last_enemy])
	AchievementManager.register_location_bonus(first_enemy.location, 2000)
	AchievementManager.track_enemy_defeat(first_enemy)

	# act
	AchievementManager.clear_locations()

	# assert
	assert_true(AchievementManager._locations.is_empty())
	assert_eq(GameSession.score, 0)


func test_empty_visit_does_not_award_a_bonus():
	# arrange
	AchievementManager.register_locations([])

	# act
	AchievementManager.register_location_bonus("dungeon_procedural_1", 2000)

	# assert
	assert_true(AchievementManager._locations.is_empty())
	assert_eq(AchievementManager.progress["dungeon"], 0)
	assert_eq(GameSession.score, 0)


func test_last_distinct_enemy_still_awards_bonus_after_a_duplicate_report():
	# arrange
	var first_enemy = _create_enemy("dungeon_procedural_1")
	var last_enemy = _create_enemy(first_enemy.location)
	AchievementManager.register_locations([first_enemy, last_enemy])
	AchievementManager.register_location_bonus(first_enemy.location, 1000)
	AchievementManager.track_enemy_defeat(first_enemy)
	AchievementManager.track_enemy_defeat(first_enemy)

	# act
	AchievementManager.track_enemy_defeat(last_enemy)

	# assert
	assert_eq(GameSession.score, 1000)
	assert_eq(AchievementManager.progress["dungeon"], 1)
	assert_true(AchievementManager._locations.is_empty())


func test_abandoned_visit_does_not_reduce_the_regenerated_population():
	# arrange
	var old_enemy = _create_enemy("dungeon_procedural_1")
	var old_survivor = _create_enemy(old_enemy.location)
	var regenerated_first = _create_enemy(old_enemy.location)
	var regenerated_last = _create_enemy(old_enemy.location)
	AchievementManager.register_locations([old_enemy, old_survivor])
	AchievementManager.register_location_bonus(old_enemy.location, 1000)
	AchievementManager.track_enemy_defeat(old_enemy)
	AchievementManager.clear_locations()
	AchievementManager.register_locations([regenerated_first, regenerated_last])
	AchievementManager.register_location_bonus(old_enemy.location, 1000)

	# act
	AchievementManager.track_enemy_defeat(regenerated_first)

	# assert
	assert_eq(AchievementManager._locations[old_enemy.location].remaining_enemies.size(), 1)
	assert_eq(AchievementManager.progress["dungeon"], 0)
	assert_eq(GameSession.score, 0)


func test_reset_discards_location_identity_and_bonus_metadata():
	# arrange
	var enemy = _create_enemy("dungeon_procedural_1")
	AchievementManager.register_locations([enemy])
	AchievementManager.register_location_bonus(enemy.location, 2000)

	# act
	AchievementManager.reset()

	# assert
	assert_true(AchievementManager._locations.is_empty())


func test_emitted_bonus_snapshot_does_not_change_after_another_clear():
	# arrange
	var first_enemy = _create_enemy("dungeon_procedural_1")
	var second_enemy = _create_enemy("dungeon_procedural_2")
	AchievementManager.register_locations([first_enemy, second_enemy])
	AchievementManager.register_location_bonus(first_enemy.location, 1000)
	AchievementManager.register_location_bonus(second_enemy.location, 2000)
	watch_signals(AchievementManager)
	AchievementManager.track_enemy_defeat(first_enemy)
	var first_event = get_signal_parameters(AchievementManager, "achievement_unlocked", 0)

	# act
	AchievementManager.track_enemy_defeat(second_enemy)

	# assert
	var second_event = get_signal_parameters(AchievementManager, "achievement_unlocked", 1)
	assert_eq(first_event[0].bonus, 1000)
	assert_eq(second_event[0].bonus, 2000)
	assert_ne(first_event[0], second_event[0])
	assert_eq(AchievementManager.ACHIEVEMENTS["dungeon"].bonus, 500)
	assert_eq(AchievementManager.recent_unlocks, ["dungeon", "dungeon"])


func test_fourth_clear_awards_the_separate_milestone_bonus():
	# arrange
	var enemy = _create_enemy("dungeon_procedural_4")
	AchievementManager.progress["dungeon"] = 3
	AchievementManager.register_locations([enemy])
	AchievementManager.register_location_bonus(enemy.location, 1000)

	# act
	AchievementManager.track_enemy_defeat(enemy)

	# assert
	assert_eq(GameSession.score, 3000)
	assert_eq(AchievementManager.progress["dungeon"], 4)
	assert_has(AchievementManager.unlocked_achievements, "dungeon_4")
	assert_eq(AchievementManager.ACHIEVEMENTS["dungeon_4"].bonus, 2000)


func test_later_clear_does_not_repeat_the_four_dungeon_milestone():
	# arrange
	var enemy = _create_enemy("dungeon_procedural_5")
	AchievementManager.progress["dungeon"] = 4
	AchievementManager.unlocked_achievements.append("dungeon_4")
	AchievementManager.register_locations([enemy])
	AchievementManager.register_location_bonus(enemy.location, 2000)

	# act
	AchievementManager.track_enemy_defeat(enemy)

	# assert
	assert_eq(GameSession.score, 2000)
	assert_eq(AchievementManager.progress["dungeon"], 5)
	assert_eq(AchievementManager.recent_unlocks, ["dungeon"])


func test_clear_bonus_is_added_to_existing_enemy_points():
	# arrange
	var enemy = _create_enemy("dungeon_procedural_1")
	AchievementManager.register_locations([enemy])
	AchievementManager.register_location_bonus(enemy.location, 1000)
	GameSession.add_score(75)

	# act
	AchievementManager.track_enemy_defeat(enemy)

	# assert
	assert_eq(GameSession.score, 1075)
	assert_eq(AchievementManager.progress["score"], 1075)


func test_classic_dungeon_after_procedural_visit_keeps_its_default_bonus():
	# arrange
	var enemy = _create_enemy("dungeon_procedural_1")
	AchievementManager.register_locations([enemy])
	AchievementManager.register_location_bonus(enemy.location, 2000)
	AchievementManager.clear_locations()
	AchievementManager.register_locations([enemy])

	# act
	AchievementManager.track_enemy_defeat(enemy)

	# assert
	assert_eq(GameSession.score, 500)


func _create_enemy(location: String) -> Enemy:
	var enemy = autofree(Enemy.new())
	enemy.stats = EnemyStats.new()
	enemy.location = location
	return enemy


func _create_good(id: String) -> GoodResource:
	var resource := GoodResource.new()
	resource.id = id
	resource.name = id
	return resource
