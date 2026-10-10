class_name QuestLogGui
extends Control

const COMPLETED_COLOR: Color = Color(0.4, 0.85, 0.4)
const HINT_COLOR: Color = Color(0.75, 0.75, 0.75)
const COMPLETED_MARK: String = "✔"
const OPEN_MARK: String = "•"


@onready var quest_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/QuestList

var quest_log: QuestLog = QuestLog.new()


func _process(_delta: float) -> void:
	if GameSession.quiz_dialog_displayed:
		_close()
		return
	if not Input.is_action_just_pressed("quest_log"):
		return
	if visible:
		_close()
	elif not get_tree().paused:
		_open()


func _open() -> void:
	_rebuild()
	visible = true
	get_tree().paused = true


func _close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func _rebuild() -> void:
	for child in quest_list.get_children():
		child.queue_free()
		quest_list.remove_child(child)
	
	for quest in quest_log.quests:
		quest_list.add_child(_create_row(quest))


func _create_row(quest: Quest) -> HBoxContainer:
	var completed = quest_log.get_status(quest) == QuestLog.Status.COMPLETED
	
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_create_mark_label(completed))
	row.add_child(_create_text_box(quest, completed))
	row.add_child(_create_progress_label(quest, completed))
	return row


func _create_mark_label(completed: bool) -> Label:
	var label = Label.new()
	label.text = COMPLETED_MARK if completed else OPEN_MARK
	label.custom_minimum_size.x = 14
	label.add_theme_font_size_override("font_size", 11)
	if completed:
		label.add_theme_color_override("font_color", COMPLETED_COLOR)
	return label


func _create_text_box(quest: Quest, completed: bool) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	
	var title_label = Label.new()
	title_label.text = quest.title
	title_label.add_theme_font_size_override("font_size", 11)
	if completed:
		title_label.add_theme_color_override("font_color", COMPLETED_COLOR)
	box.add_child(title_label)
	
	if not completed:
		var hint_label = Label.new()
		hint_label.text = quest.hint
		hint_label.add_theme_font_size_override("font_size", 9)
		hint_label.add_theme_color_override("font_color", HINT_COLOR)
		box.add_child(hint_label)
	
	return box


func _create_progress_label(quest: Quest, completed: bool) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.custom_minimum_size.x = 40
	
	var progress = quest_log.get_progress(quest)
	if progress.y > 1 and not completed:
		label.text = "%d / %d" % [progress.x, progress.y]
	
	if completed:
		label.add_theme_color_override("font_color", COMPLETED_COLOR)
	return label
