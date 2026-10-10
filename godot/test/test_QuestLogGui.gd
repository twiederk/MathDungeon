extends GutTest

var gui: QuestLogGui = null


func before_each():
	gui = add_child_autofree(preload("res://gui/quest_log_gui.tscn").instantiate())


func after_each():
	AchievementManager.reset()
	GameSession.reset()


func test_quest_log_starts_hidden():
	# assert
	assert_false(gui.visible)


func test_one_row_per_quest():
	# act
	gui._rebuild()
	
	# assert
	assert_eq(gui.quest_log.quests.size(), gui.quest_list.get_child_count())


func test_completed_quest_row_is_marked():
	# arrange
	AchievementManager._unlock_achievement(gui.quest_log.quests[0].achievement_id)
	
	# act
	gui._rebuild()
	
	# assert
	assert_eq(QuestLogGui.COMPLETED_MARK, _mark_of_row(0))


func test_open_quest_row_is_not_marked():
	# act
	gui._rebuild()
	
	# assert
	assert_eq(QuestLogGui.OPEN_MARK, _mark_of_row(0))


func _mark_of_row(index: int) -> String:
	var label = gui.quest_list.get_child(index).get_child(0) as Label
	return label.text
