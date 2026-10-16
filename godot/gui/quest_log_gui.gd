class_name QuestLogGui
extends Control

const QUEST_ROW_SCENE := preload("res://gui/quest_row.tscn")


@onready var quest_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/QuestList

var quest_log: QuestLog = QuestLog.new()


func _ready() -> void:
	GameSession.display_state_changed.connect(_on_display_state_changed)
	_on_display_state_changed(GameSession.display_state)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("quest_log"):
		match GameSession.display_state:
			GameSession.DisplayState.NONE:
				GameSession.display_state = GameSession.DisplayState.QUEST_LOG
			GameSession.DisplayState.QUEST_LOG:
				GameSession.display_state = GameSession.DisplayState.NONE


func _on_display_state_changed(state: int) -> void:
	if state == GameSession.DisplayState.QUEST_LOG:
		_show_menu()
	else:
		_hide_menu()


func _show_menu() -> void:
	for child in quest_list.get_children():
		child.queue_free()
		quest_list.remove_child(child)
	
	for quest in quest_log.quests:
		_create_row(quest)
	
	visible = true


func _hide_menu() -> void:
	visible = false


func _create_row(quest: Quest) -> void:
	var completed = quest_log.get_status(quest) == QuestLog.Status.COMPLETED
	var quest_row: QuestRow = QUEST_ROW_SCENE.instantiate()
	quest_list.add_child(quest_row)
	quest_row.setup(quest, completed, quest_log.get_progress(quest))
