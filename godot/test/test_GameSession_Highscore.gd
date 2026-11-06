extends GutTest

var original_highscores: Array = []


func before_each():
	original_highscores = HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL].duplicate()
	HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL] = []


func after_each():
	HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL] = original_highscores
	GameSession.reset()


func test_add_score_emits_highscore_rank_changed_when_score_qualifies():
	# arrange
	watch_signals(GameSession)

	# act
	GameSession.add_score(10)

	# assert
	assert_signal_emitted_with_parameters(GameSession, "highscore_rank_changed", [1])


func test_add_score_does_not_emit_highscore_rank_changed_when_the_rank_stays():
	# arrange
	GameSession.add_score(10)
	watch_signals(GameSession)

	# act
	GameSession.add_score(5)

	# assert
	assert_signal_not_emitted(GameSession, "highscore_rank_changed")


func test_add_score_does_not_emit_highscore_rank_changed_when_score_does_not_qualify():
	# arrange
	var full_highscores: Array[Highscore] = []
	for i in range(HighscoreManager.MAX_HIGHSCORES):
		full_highscores.append(Highscore.new("Player%d" % i, 100 + i))
	HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL] = full_highscores
	watch_signals(GameSession)

	# act
	GameSession.add_score(1)

	# assert
	assert_signal_not_emitted(GameSession, "highscore_rank_changed")


func test_add_score_emits_highscore_rank_changed_when_the_rank_improves():
	# arrange
	var highscores: Array[Highscore] = []
	for i in range(HighscoreManager.MAX_HIGHSCORES):
		highscores.append(Highscore.new("Player%d" % i, 100 - i * 10))
	HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL] = highscores
	GameSession.add_score(15)
	watch_signals(GameSession)

	# act
	GameSession.add_score(10)

	# assert
	assert_signal_emitted_with_parameters(GameSession, "highscore_rank_changed", [9])


func test_reset_clears_the_highscore_rank():
	# arrange
	GameSession.add_score(10)
	GameSession.reset()
	watch_signals(GameSession)

	# act
	GameSession.add_score(5)

	# assert
	assert_signal_emitted_with_parameters(GameSession, "highscore_rank_changed", [1])
