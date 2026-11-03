extends GutTest

const COUNTDOWN_TIMER_WIDGET_SCENE = preload("res://gui/countdown_timer_widget.tscn")

var widget: CountdownTimerWidget


func before_each():
	widget = add_child_autofree(COUNTDOWN_TIMER_WIDGET_SCENE.instantiate())


func after_each():
	widget = null
	GameSession.game_mode = GameSession.GameMode.NORMAL
	GameSession.run_time_left = 0.0


func test_format_time_for_the_full_duration():
	# act
	var text = widget.format_time(600.0)
	
	# assert
	assert_eq(text, "10:00")


func test_format_time_rounds_up_partial_seconds():
	# act
	var text = widget.format_time(59.4)
	
	# assert
	assert_eq(text, "1:00")


func test_format_time_for_zero_seconds():
	# act
	var text = widget.format_time(0.0)
	
	# assert
	assert_eq(text, "0:00")


func test_widget_is_hidden_in_normal_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.NORMAL
	
	# act
	widget._update_visibility()
	
	# assert
	assert_false(widget.visible)


func test_widget_is_visible_in_timed_run_mode():
	# arrange
	GameSession.game_mode = GameSession.GameMode.TIMED_RUN
	
	# act
	widget._update_visibility()
	
	# assert
	assert_true(widget.visible)
