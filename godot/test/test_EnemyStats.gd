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
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.NORMAL
	zombie_stats = null
	skeleton_stats = null
	piglin_stats = null
	spider_stats = null
	enderman_stats = null
	enderdragon_stats = null


func test_zombie_stats_score():
	# Act
	var actual_score = zombie_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 8)


func test_skeleton_stats_score():
	# Act
	var actual_score = skeleton_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 12)


func test_piglin_stats_score():
	# Act
	var actual_score = piglin_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 28)


func test_spider_stats_score():
	# Act
	var actual_score = spider_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 136)


func test_enderman_stats_score():
	# Act
	var actual_score = enderman_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 212)


func test_enderdragon_stats_score():
	# Act
	var actual_score = enderdragon_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 254)


func test_zombie_stats_score_hard():
	# Arrange
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.HARD
	
	# Act
	var actual_score = zombie_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 130)


func test_spider_stats_score_hard():
	# Arrange
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.HARD
	
	# Act
	var actual_score = spider_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 184)


func test_enderdragon_stats_score_hard():
	# Arrange
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.HARD
	
	# Act
	var actual_score = enderdragon_stats.get_score()
	
	# Assert
	assert_eq(actual_score, 284)


func test_zombie_stats_hard_values():
	# Arrange
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.HARD
	
	# Assert
	assert_eq(zombie_stats.get_max_hit_points(), 3)
	assert_eq(zombie_stats.get_max_number(), 40)
	assert_eq(zombie_stats.get_time_limit(), 30)
	assert_true(zombie_stats.has_time_limit())
	# not overridden, falls back to the normal value
	assert_eq(zombie_stats.get_damage(), 1)
	assert_eq(zombie_stats.get_armor(), 0)


func test_unset_hard_values_fall_back_to_normal():
	# Arrange
	var stats := EnemyStats.new()
	stats.max_hit_points = 4
	stats.damage = 2
	stats.armor = 1
	stats.max_number = 50
	stats.time_limit = 25
	var normal_score := stats.get_score()
	
	# Act
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.HARD
	
	# Assert
	assert_eq(stats.get_max_hit_points(), 4)
	assert_eq(stats.get_damage(), 2)
	assert_eq(stats.get_armor(), 1)
	assert_eq(stats.get_max_number(), 50)
	assert_eq(stats.get_time_limit(), 25)
	assert_eq(stats.get_arithmetic(), stats.arithmetic)
	assert_eq(stats.get_score(), normal_score)


func test_hard_time_limit_minus_one_disables_time_limit():
	# Arrange
	var stats := EnemyStats.new()
	stats.time_limit = 20
	stats.hard_time_limit = -1
	
	# Act
	PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.HARD
	
	# Assert
	assert_eq(stats.get_time_limit(), -1)
	assert_false(stats.has_time_limit())
