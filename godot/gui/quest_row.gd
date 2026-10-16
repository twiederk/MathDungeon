class_name QuestRow
extends HBoxContainer

const COMPLETED_COLOR: Color = Color(0.4, 0.85, 0.4)
const HINT_COLOR: Color = Color(0.75, 0.75, 0.75)
const COMPLETED_MARK: String = "✔"
const OPEN_MARK: String = "•"

@onready var mark_label: Label = $MarkLabel
@onready var title_label: Label = $TextBox/TitleLabel
@onready var hint_label: Label = $TextBox/HintLabel
@onready var progress_label: Label = $ProgressLabel


func setup(quest: Quest, completed: bool, progress: Vector2i) -> void:
	mark_label.text = COMPLETED_MARK if completed else OPEN_MARK
	title_label.text = quest.title
	hint_label.text = quest.hint
	hint_label.visible = not completed
	progress_label.text = "%d / %d" % [progress.x, progress.y] if progress.y > 1 and not completed else ""

	if completed:
		mark_label.add_theme_color_override("font_color", COMPLETED_COLOR)
		title_label.add_theme_color_override("font_color", COMPLETED_COLOR)
		progress_label.add_theme_color_override("font_color", COMPLETED_COLOR)
