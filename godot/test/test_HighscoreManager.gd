extends GutTest

const TEST_NORMAL_PATH := "user://test_high_scores"
const TEST_TIMED_RUN_PATH := "user://test_high_scores_10min"

var original_normal: Array = []
var original_timed_run: Array = []
var original_highscore_paths: Dictionary = {}


func before_each():
	original_normal = HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL].duplicate()
	original_timed_run = HighscoreManager.highscores_by_mode[GameSession.GameMode.TIMED_RUN].duplicate()
	original_highscore_paths = HighscoreManager.highscore_paths.duplicate()
	HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL] = []
	HighscoreManager.highscores_by_mode[GameSession.GameMode.TIMED_RUN] = []
	HighscoreManager.highscore_paths = {
		GameSession.GameMode.NORMAL: TEST_NORMAL_PATH,
		GameSession.GameMode.TIMED_RUN: TEST_TIMED_RUN_PATH
	}


func after_each():
	HighscoreManager.highscores_by_mode[GameSession.GameMode.NORMAL] = original_normal
	HighscoreManager.highscores_by_mode[GameSession.GameMode.TIMED_RUN] = original_timed_run
	HighscoreManager.highscore_paths = original_highscore_paths
	for path in [TEST_NORMAL_PATH, TEST_TIMED_RUN_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	GameSession.reset()


func test_add_score_in_timed_run_does_not_appear_in_normal_list():
	# act
	HighscoreManager.add_score("Player", 10, GameSession.DifficultyLevel.NORMAL, 0, GameSession.GameMode.TIMED_RUN)
	
	# assert
	assert_true(HighscoreManager.get_highscores(GameSession.GameMode.NORMAL).is_empty())


func test_add_score_in_normal_mode_does_not_appear_in_timed_run_list():
	# act
	HighscoreManager.add_score("Player", 10, GameSession.DifficultyLevel.NORMAL, 0, GameSession.GameMode.NORMAL)
	
	# assert
	assert_true(HighscoreManager.get_highscores(GameSession.GameMode.TIMED_RUN).is_empty())


func test_add_score_in_timed_run_appears_in_the_timed_run_list():
	# act
	HighscoreManager.add_score("Player", 10, GameSession.DifficultyLevel.NORMAL, 0, GameSession.GameMode.TIMED_RUN)
	var entries = HighscoreManager.get_highscores(GameSession.GameMode.TIMED_RUN)
	
	# assert
	assert_eq(entries.size(), 1)


func test_is_highscore_evaluates_against_the_given_mode():
	# arrange
	var full_highscores: Array[Highscore] = []
	for i in range(HighscoreManager.MAX_HIGHSCORES):
		full_highscores.append(Highscore.new("Player%d" % i, 100 + i))
	HighscoreManager.highscores_by_mode[GameSession.GameMode.TIMED_RUN] = full_highscores
	
	# act
	var is_highscore = HighscoreManager.is_highscore(1, GameSession.GameMode.TIMED_RUN)
	
	# assert
	assert_false(is_highscore)


func test_is_highscore_ignores_the_other_modes_list():
	# arrange
	var full_highscores: Array[Highscore] = []
	for i in range(HighscoreManager.MAX_HIGHSCORES):
		full_highscores.append(Highscore.new("Player%d" % i, 100 + i))
	HighscoreManager.highscores_by_mode[GameSession.GameMode.TIMED_RUN] = full_highscores
	
	# act
	var is_highscore = HighscoreManager.is_highscore(1, GameSession.GameMode.NORMAL)
	
	# assert
	assert_true(is_highscore)


func test_normal_list_is_capped_at_max_highscores():
	# act
	for i in range(HighscoreManager.MAX_HIGHSCORES + 5):
		HighscoreManager.add_score("Player%d" % i, i, GameSession.DifficultyLevel.NORMAL, 0, GameSession.GameMode.NORMAL)
	var entries = HighscoreManager.get_highscores(GameSession.GameMode.NORMAL)
	
	# assert
	assert_eq(entries.size(), HighscoreManager.MAX_HIGHSCORES)


func test_timed_run_list_is_capped_at_max_highscores():
	# act
	for i in range(HighscoreManager.MAX_HIGHSCORES + 5):
		HighscoreManager.add_score("Player%d" % i, i, GameSession.DifficultyLevel.NORMAL, 0, GameSession.GameMode.TIMED_RUN)
	var entries = HighscoreManager.get_highscores(GameSession.GameMode.TIMED_RUN)
	
	# assert
	assert_eq(entries.size(), HighscoreManager.MAX_HIGHSCORES)
