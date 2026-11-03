class_name CountdownTimerWidget
extends Control


const WARNING_THRESHOLD_SECONDS := 60.0
const WARNING_COLOR := Color(1, 0, 0)
const NORMAL_COLOR := Color(1, 1, 1)

@onready var time_label: Label = $TimeLabel


func _ready() -> void:
	GameSession.run_time_changed.connect(_on_run_time_changed)
	GameSession.game_mode_changed.connect(_on_game_mode_changed)
	_update_visibility()
	update_time()


func _on_run_time_changed(_seconds_left: float) -> void:
	update_time()


func _on_game_mode_changed(_mode: GameSession.GameMode) -> void:
	_update_visibility()


func _update_visibility() -> void:
	visible = GameSession.is_timed_run()


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
