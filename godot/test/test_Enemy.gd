extends GutTest


const ENEMY_SCENE = preload("res://enemies/enderman.tscn")

var enemy: Enemy


func before_each():
	enemy = ENEMY_SCENE.instantiate()
	watch_signals(enemy)


func after_each():
	enemy.free()
	enemy = null


func test_nonlethal_damage_does_not_emit_defeated():
	# arrange
	enemy.hit_points = enemy.stats.get_max_hit_points()

	# act
	enemy.hurt(1)

	# assert
	assert_signal_not_emitted(enemy, "defeated")


func test_lethal_damage_emits_defeated():
	# arrange
	enemy.hit_points = enemy.stats.get_max_hit_points()

	# act
	enemy.hurt(100)

	# assert
	assert_signal_emitted(enemy, "defeated")
