extends GutTest

var quest_log: QuestLog = null


func before_each():
	quest_log = QuestLog.new()


func after_each():
	AchievementManager.reset()
	GameSession.reset()



func test_unlocking_the_achievement_completes_the_quest():
	# arrange
	var quest = _quest("lighter")
	
	# act
	GameSession.has_lighter = true
	
	# assert
	assert_eq(QuestLog.Status.COMPLETED, quest_log.get_status(quest))
	assert_true(quest_log.is_completed(quest))


func test_reset_reopens_all_quests():
	# arrange
	GameSession.has_lighter = true
	GameSession.eyes_of_ender = 12
	
	# act
	AchievementManager.reset()
	
	# assert
	assert_eq(QuestLog.Status.OPEN, quest_log.get_status(_quest("lighter")))
	assert_eq(QuestLog.Status.OPEN, quest_log.get_status(_quest("eyes_of_ender")))


func test_progress_of_a_counting_quest():
	# arrange
	var quest = _quest("eyes_of_ender")
	
	# act
	GameSession.eyes_of_ender = 7
	
	# assert
	assert_eq(Vector2i(7, 12), quest_log.get_progress(quest))
	assert_true(quest_log.has_progress_bar(quest))


func test_progress_is_capped_at_the_target():
	# arrange
	var quest = _quest("eyes_of_ender")
	
	# act
	GameSession.eyes_of_ender = 15
	
	# assert
	assert_eq(Vector2i(12, 12), quest_log.get_progress(quest))


func test_one_shot_quest_has_no_progress_bar():
	# assert
	assert_false(quest_log.has_progress_bar(_quest("lighter")))


func _quest(id: String) -> Quest:
	for quest in quest_log.quests:
		if quest.id == id:
			return quest
	fail_test("No quest with id '%s'" % id)
	return null
