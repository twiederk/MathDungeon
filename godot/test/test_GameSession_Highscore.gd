extends GutTest

var original_highscores: Array[Highscore]


func before_each():
	original_highscores = HighscoreManager.highscores.duplicate()
	HighscoreManager.highscores = []


func after_each():
	HighscoreManager.highscores = original_highscores
	GameSession.reset()


func test_add_score_emits_entered_highscores_when_score_qualifies():
	# arrange
	watch_signals(GameSession)

	# act
	GameSession.add_score(10)

	# assert
	assert_signal_emitted(GameSession, "entered_highscores")


func test_add_score_does_not_emit_entered_highscores_twice():
	# arrange
	GameSession.add_score(10)
	watch_signals(GameSession)

	# act
	GameSession.add_score(5)

	# assert
	assert_signal_not_emitted(GameSession, "entered_highscores")


func test_add_score_does_not_emit_entered_highscores_when_score_does_not_qualify():
	# arrange
	var full_highscores: Array[Highscore] = []
	for i in range(HighscoreManager.MAX_HIGHSCORES):
		full_highscores.append(Highscore.new("Player%d" % i, 100 + i))
	HighscoreManager.highscores = full_highscores
	watch_signals(GameSession)

	# act
	GameSession.add_score(1)

	# assert
	assert_signal_not_emitted(GameSession, "entered_highscores")


func test_reset_clears_entered_highscores_flag():
	# arrange
	GameSession.add_score(10)
	GameSession.reset()
	watch_signals(GameSession)

	# act
	GameSession.add_score(5)

	# assert
	assert_signal_emitted(GameSession, "entered_highscores")
