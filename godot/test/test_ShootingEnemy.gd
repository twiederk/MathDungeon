extends GutTest


const BLAZE_SCENE = preload("res://enemies/blaze.tscn")

var shooting_enemy: ShootingEnemy


func before_each():
	shooting_enemy = add_child_autofree(BLAZE_SCENE.instantiate())


func after_each():
	shooting_enemy = null


func test_single_fire_delay_cycle():
	# Arrange
	shooting_enemy.fire_delays = [1.5] as Array[float]
	shooting_enemy._delay_index = 0
	
	# Act
	var actual_wait_times = _collect_wait_times(shooting_enemy, 3)
	
	# Assert
	assert_eq(actual_wait_times, [1.5, 1.5, 1.5])


func test_blaze_fire_delays_cycle():
	# Arrange
	shooting_enemy.fire_delays = [0.4, 0.4, 0.4, 3.0] as Array[float]
	shooting_enemy._delay_index = 0

	# Act
	var actual_wait_times = _collect_wait_times(shooting_enemy, 8)
	
	# Assert
	assert_eq(actual_wait_times, [0.4, 0.4, 0.4, 3.0, 0.4, 0.4, 0.4, 3.0])


func test_start_shooting_restarts_cycle():
	# Arrange
	shooting_enemy.fire_delays = [0.4, 0.4, 3.0] as Array[float]
	shooting_enemy._delay_index = 0
	_collect_wait_times(shooting_enemy, 2)
	shooting_enemy._start_shooting()
	shooting_enemy._stop_shooting()
	
	# Act
	var actual_wait_times = _collect_wait_times(shooting_enemy, 3)
	
	# Assert
	assert_eq(actual_wait_times, [0.4, 0.4, 3.0])


func _collect_wait_times(enemy: ShootingEnemy, count: int) -> Array:
	var wait_times: Array = []
	for i in count:
		enemy._restart_fire_timer()
		wait_times.append(enemy.fire_timer.wait_time)
	return wait_times
