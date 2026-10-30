extends GutTest

var zombie_stats: EnemyStats
var skeleton_stats: EnemyStats
var piglin_stats: EnemyStats
var spider_stats: EnemyStats
var enderman_stats: EnemyStats
var enderdragon_stats: EnemyStats


func before_each():
	zombie_stats = load("res://enemies/zombie_stats.tres")
	skeleton_stats = load("res://enemies/skeleton_stats.tres")
	piglin_stats = load("res://enemies/piglin_stats.tres")
	spider_stats = load("res://enemies/spider_stats.tres")
	enderman_stats = load("res://enemies/enderman_stats.tres")
	enderdragon_stats = load("res://enemies/enderdragon_stats.tres")


func after_each():
	GameSession.difficulty_level = GameSession.DifficultyLevel.NORMAL
	zombie_stats = null
	skeleton_stats = null
	piglin_stats = null
	spider_stats = null
	enderman_stats = null
	enderdragon_stats = null


func test_zombie_stats_score():
	# act
	var actual_score = zombie_stats.get_score()
	
	# assert
	assert_eq(actual_score, 8)


func test_skeleton_stats_score():
	# act
	var actual_score = skeleton_stats.get_score()
	
	# assert
	assert_eq(actual_score, 12)


func test_piglin_stats_score():
	# act
	var actual_score = piglin_stats.get_score()
	
	# assert
	assert_eq(actual_score, 28)


func test_spider_stats_score():
	# act
	var actual_score = spider_stats.get_score()
	
	# assert
	assert_eq(actual_score, 136)


func test_enderman_stats_score():
	# act
	var actual_score = enderman_stats.get_score()
	
	# assert
	assert_eq(actual_score, 212)


func test_enderdragon_stats_score():
	# act
	var actual_score = enderdragon_stats.get_score()
	
	# assert
	assert_eq(actual_score, 254)


func test_zombie_stats_score_hard():
	# arrange
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# act
	var actual_score = zombie_stats.get_score()
	
	# assert
	assert_eq(actual_score, 130)


func test_spider_stats_score_hard():
	# arrange
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# act
	var actual_score = spider_stats.get_score()
	
	# assert
	assert_eq(actual_score, 184)


func test_enderdragon_stats_score_hard():
	# arrange
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# act
	var actual_score = enderdragon_stats.get_score()
	
	# assert
	assert_eq(actual_score, 284)


func test_zombie_stats_hard_values():
	# arrange
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# assert
	assert_eq(zombie_stats.get_max_hit_points(), 3)
	assert_eq(zombie_stats.get_max_number(), 40)
	assert_eq(zombie_stats.get_time_limit(), 30)
	assert_true(zombie_stats.has_time_limit())
	assert_eq(zombie_stats.get_damage(), 1)
	assert_eq(zombie_stats.get_armor(), 0)


func test_unset_hard_values_fall_back_to_normal():
	# arrange
	var stats := EnemyStats.new()
	stats.max_hit_points = 4
	stats.damage = 2
	stats.armor = 1
	stats.max_number = 50
	stats.time_limit = 25
	var normal_score := stats.get_score()
	
	# act
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# assert
	assert_eq(stats.get_max_hit_points(), 4)
	assert_eq(stats.get_damage(), 2)
	assert_eq(stats.get_armor(), 1)
	assert_eq(stats.get_max_number(), 50)
	assert_eq(stats.get_time_limit(), 25)
	assert_eq(stats.get_arithmetic(), stats.arithmetic)
	assert_eq(stats.get_score(), normal_score)


func test_hard_time_limit_not_set_falls_back_to_normal_time_limit():
	# arrange
	var stats := EnemyStats.new()
	stats.time_limit = 20
	stats.hard_time_limit = EnemyStats.NOT_SET
	
	# act
	GameSession.difficulty_level = GameSession.DifficultyLevel.HARD
	
	# assert
	assert_eq(stats.get_time_limit(), 20)
	assert_true(stats.has_time_limit())


func test_get_hurt_sound_falls_back_to_default_when_empty():
	# arrange
	var stats := EnemyStats.new()
	
	# act
	var actual_sound = stats.get_hurt_sound()
	
	# assert
	assert_eq(actual_sound, Sound.hurt_enemy)


func test_get_hurt_sound_returns_single_configured_sound():
	# arrange
	var stats := EnemyStats.new()
	var sound := AudioStreamWAV.new()
	stats.hurt_sounds = [sound]
	
	# act
	var actual_sound = stats.get_hurt_sound()
	
	# assert
	assert_eq(actual_sound, sound)


func test_get_hurt_sound_returns_one_of_the_configured_sounds():
	# arrange
	var stats := EnemyStats.new()
	stats.hurt_sounds = [AudioStreamWAV.new(), AudioStreamWAV.new(), AudioStreamWAV.new()]
	
	# act
	var actual_sound = stats.get_hurt_sound()
	
	# assert
	assert_has(stats.hurt_sounds, actual_sound)


func test_all_non_projectile_stats_define_hurt_sounds():
	# arrange
	var projectiles := ["arrow_stats", "fireball_stats", "blaze_fireball_stats"]
	var dir := DirAccess.open("res://enemies")
	var without_sounds: Array[String] = []
	for file_name in dir.get_files():
		if not file_name.ends_with("_stats.tres"):
			continue
		if file_name.get_basename() in projectiles:
			continue
		var stats: EnemyStats = load("res://enemies/" + file_name)
		if stats.hurt_sounds.is_empty():
			without_sounds.append(file_name)
	
	# act
	var actual_count = without_sounds.size()
	
	# assert
	assert_eq(actual_count, 0, "stats without hurt_sounds: %s" % [without_sounds])


func test_get_death_sound_falls_back_to_default_when_empty():
	# arrange
	var stats := EnemyStats.new()
	
	# act
	var actual_sound = stats.get_death_sound()
	
	# assert
	assert_eq(actual_sound, Sound.death_enemy)


func test_get_death_sound_returns_one_of_the_configured_sounds():
	# arrange
	var stats := EnemyStats.new()
	stats.death_sounds = [AudioStreamWAV.new(), AudioStreamWAV.new(), AudioStreamWAV.new()]
	
	# act
	var actual_sound = stats.get_death_sound()
	
	# assert
	assert_has(stats.death_sounds, actual_sound)
