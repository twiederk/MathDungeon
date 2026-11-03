class_name CountdownTimerWidget
extends Control


const WARNING_THRESHOLD_SECONDS := 60.0
const WARNING_COLOR := Color(1, 0, 0)
const NORMAL_COLOR := Color(1, 1, 1)

@onready var time_label: Label = $TimeLabel


func _ready() -> void:
	GameSession.run_time_changed.connect(_on_run_time_changed)
	update_time()


func _on_run_time_changed(_seconds_left: float) -> void:
	update_time()


func update_time() -> void:
	time_label.text = "Zeit: " + format_time(GameSession.run_time_left)
	if GameSession.run_time_left < WARNING_THRESHOLD_SECONDS:
		time_label.add_theme_color_override("font_color", WARNING_COLOR)
	else:
		time_label.add_theme_color_override("font_color", NORMAL_COLOR)


func format_time(seconds: float) -> String:
	var total_seconds := int(ceil(seconds))
	@warning_ignore("integer_division")
	var minutes := total_seconds / 60
	var secs := total_seconds % 60
	return "%d:%02d" % [minutes, secs]
