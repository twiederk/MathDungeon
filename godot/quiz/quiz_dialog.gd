class_name QuizDialog
extends Control

@onready var question_label: Label = $CenterContainer/VBoxContainer/QuestionLabel
@onready var answer_line_edit: LineEdit = $CenterContainer/VBoxContainer/AnswerLineEdit
@onready var start_gui_button: Button = $CenterContainer/VBoxContainer/StartGuiButton
@onready var time_limit_progress_bar: ProgressBar = $CenterContainer/VBoxContainer/TimelimitProgressBar
@onready var answer_timer = $AnswerTimer
@onready var progress_timer = $ProgressTimer


var enemy: Enemy = null
var exercise: Exercise


func open_for(my_enemy: Enemy) -> void:
	enemy = my_enemy
	_setup_exercise()
	_setup_time_limit_progress_bar()
	_setup_enemy_health_meter_widget()
	visible = true
	answer_line_edit.grab_focus()
	get_tree().paused = true

func _setup_exercise() -> void:
	exercise = _create_exercise()
	question_label.text = exercise.question
	answer_line_edit.text = ""


func _setup_time_limit_progress_bar() -> void:
	if enemy.has_time_limit():
		time_limit_progress_bar.visible = true
		_start_timers()
	else:
		time_limit_progress_bar.visible = false


func _setup_enemy_health_meter_widget() -> void:
	pass


func _start_timers() -> void:
	time_limit_progress_bar.value = 0
	time_limit_progress_bar.max_value = enemy.stats.time_limit
	answer_timer.wait_time = enemy.stats.time_limit
	answer_timer.start()
	progress_timer.start()


func _create_exercise() -> Exercise:
	var arithmetic = enemy.stats.arithmetic.pick_random()
	match arithmetic:
		EnemyStats.ArithmeticType.ADDITION:
			return AdditionExerciseGenerator.new(enemy.stats.max_number).create_exercise()
		EnemyStats.ArithmeticType.SUBSTRACTION:
			return SubtractionExerciseGenerator.new(enemy.stats.max_number).create_exercise()
		EnemyStats.ArithmeticType.MULTIPLICATION:
			return MultiplicationExerciseGenerator.new().create_exercise()
		EnemyStats.ArithmeticType.DIVISION:
			return DivisionExerciseGenerator.new(enemy.stats.max_number).create_exercise()
		EnemyStats.ArithmeticType.DIVISION_REMAINDER:
			return DivisionRemainderExerciseGenerator.new(enemy.stats.max_number).create_exercise()
		EnemyStats.ArithmeticType.TIMES_TABLE:
			return TimesTableExerciseGenerator.new().create_exercise()
	return AdditionExerciseGenerator.new(enemy.stats.max_number).create_exercise()


func _on_text_submitted(text: String) -> void:
	var answer: String = text.strip_edges().to_upper()
	_check_answer(answer)


func _check_answer(answer: String) -> void:
	if answer.is_empty():
		return
	if answer == exercise.result:
		_answer_correct()
	else:
		_answer_incorrect()


func _answer_correct() -> void:
	enemy.hit_points -= PlayerStats.damage
	if enemy.hit_points > 0:
		exercise = _create_exercise()
		question_label.text = "Richtig!!!\n" + exercise.question
		answer_line_edit.text = ""
		if enemy.has_time_limit():
			_start_timers()
	else:
		if enemy.has_time_limit():
			answer_timer.stop()
			progress_timer.stop()
		enemy.queue_free()
		_close_dialog()


func _answer_incorrect() -> void:
	PlayerStats.hit_points -= enemy.stats.damage
	if PlayerStats.hit_points > 0:
		question_label.text = "Nicht ganz. Versuch es nochmal:\n" + exercise.question
		answer_line_edit.text = ""
	else:
		_game_over()


func _game_over() -> void:
	question_label.text = "Du hast alle Lebenspunkte verloren.\nDu hast verloren."
	answer_line_edit.text = ""
	answer_line_edit.visible = false
	start_gui_button.visible = true
	start_gui_button.grab_focus()
	if enemy.has_time_limit():
		answer_timer.stop()
		progress_timer.stop()



func _close_dialog() -> void:
	visible = false
	get_tree().paused = false
	enemy = null
	exercise = null


func _on_answer_timer_timeout() -> void:
	time_limit_progress_bar.value = enemy.stats.time_limit
	progress_timer.stop()
	_answer_timeout()


func _on_progress_timer_timeout() -> void:
	var elapsed_time = answer_timer.wait_time - answer_timer.time_left
	time_limit_progress_bar.value = elapsed_time


func _answer_timeout() -> void:
	PlayerStats.hit_points -= enemy.stats.damage
	if PlayerStats.hit_points > 0:
		exercise = _create_exercise()
		question_label.text = "*** Zeitlimit überschritten ***\n" + exercise.question
		answer_line_edit.text = ""
		_start_timers()
	else:
		question_label.text = "GAME OVER\nDu hast verloren."
		answer_line_edit.visible = false


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")
