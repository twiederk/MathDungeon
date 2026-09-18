extends GutTest

var blaze: ShootingEnemy


func before_each():
	blaze = add_child_autofree(load("res://enemies/blaze.tscn").instantiate())


func after_each():
	blaze = null


func _collect_wait_times(enemy: ShootingEnemy, count: int) -> Array:
	var wait_times: Array = []
	for i in count:
		enemy._restart_fire_timer()
		wait_times.append(enemy.fire_timer.wait_time)
	return wait_times


func test_blaze_fire_delays():
	# Assert
	assert_eq(blaze.fire_delays, [0.4, 0.4, 0.4, 3.0] as Array[float])


func test_fire_delays_cycle():
	# Act
	var actual_wait_times = _collect_wait_times(blaze, 8)
	
	# Assert
	assert_eq(actual_wait_times, [0.4, 0.4, 0.4, 3.0, 0.4, 0.4, 0.4, 3.0])


func test_start_shooting_restarts_cycle():
	# Arrange
	_collect_wait_times(blaze, 2)
	
	# Act
	blaze._start_shooting()
	blaze._stop_shooting()
	var actual_wait_times = _collect_wait_times(blaze, 3)
	
	# Assert
	assert_eq(actual_wait_times, [0.4, 0.4, 3.0])


func test_single_delay_stays_constant():
	# Arrange
	blaze.fire_delays = [1.5] as Array[float]
	blaze._delay_index = 0
	
	# Act
	var actual_wait_times = _collect_wait_times(blaze, 3)
	
	# Assert
	assert_eq(actual_wait_times, [1.5, 1.5, 1.5])
