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
