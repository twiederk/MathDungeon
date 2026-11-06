extends GutTest

const HIGHSCORE_RANK_WIDGET_SCENE = preload("res://gui/highscore_rank_widget.tscn")

var highscore_rank_widget: HighscoreRankWidget


func before_each():
	highscore_rank_widget = add_child_autofree(HIGHSCORE_RANK_WIDGET_SCENE.instantiate())


func after_each():
	highscore_rank_widget = null
	GameSession.reset()


func test_format_rank_without_a_rank():
	# act
	var text = highscore_rank_widget.format_rank(HighscoreManager.NO_RANK)
	
	# assert
	assert_eq(text, "Kein Bestwert")


func test_format_rank_for_the_first_rank():
	# act
	var text = highscore_rank_widget.format_rank(1)
	
	# assert
	assert_eq(text, "1. Rang")


func test_format_rank_for_the_fifth_rank():
	# act
	var text = highscore_rank_widget.format_rank(5)
	
	# assert
	assert_eq(text, "5. Rang")


func test_format_rank_for_the_last_rank():
	# act
	var text = highscore_rank_widget.format_rank(10)
	
	# assert
	assert_eq(text, "10. Rang")


func test_a_rank_change_updates_the_label():
	# arrange
	GameSession.highscore_rank = 3
	
	# act
	GameSession.highscore_rank_changed.emit(3)
	
	# assert
	assert_eq(highscore_rank_widget.rank_label.text, "3. Rang")
