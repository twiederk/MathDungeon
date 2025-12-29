class_name QuizDialog
extends Control

@onready var label: Label = $CenterContainer/VBoxContainer/Label
@onready var input: LineEdit = $CenterContainer/VBoxContainer/LineEdit
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var answer_timer = $AnswerTimer
@onready var progress_timer = $ProgressTimer

var enemy: Enemy = null
var exercise: Exercise


func open_for(my_enemy: Enemy) -> void:
	enemy = my_enemy

	exercise = _create_exercise()
	label.text = exercise.question
	input.text = ""
	visible = true

	_setup_progress_bar()

	input.grab_focus()
	get_tree().paused = true


func _setup_progress_bar() -> void:
	if enemy.has_time_limit():
		progress_bar.visible = true
		_start_timers()
	else:
		progress_bar.visible = false


func _start_timers() -> void:
	progress_bar.value = 0
	progress_bar.max_value = enemy.stats.time_limit
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
		label.text = "Richtig!!!\n" + exercise.question
		input.text = ""
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
		label.text = "Nicht ganz. Versuch es nochmal:\n" + exercise.question
		input.text = ""
	else:
		label.text = "Du hast alle Lebenspunkte verloren.\nDu hast verloren."
		input.text = ""
		if enemy.has_time_limit():
			answer_timer.stop()
			progress_timer.stop()


func _close_dialog() -> void:
	visible = false
	get_tree().paused = false
	enemy = null
	exercise = null


func _on_answer_timer_timeout() -> void:
	progress_bar.value = enemy.stats.time_limit
	progress_timer.stop()
	_answer_timeout()


func _on_progress_timer_timeout() -> void:
	var elapsed_time = answer_timer.wait_time - answer_timer.time_left
	progress_bar.value = elapsed_time


func _answer_timeout() -> void:
	PlayerStats.hit_points -= enemy.stats.damage
	if PlayerStats.hit_points > 0:
		exercise = _create_exercise()
		label.text = "*** Zeitlimit überschritten ***\n" + exercise.question
		input.text = ""
		_start_timers()
	else:
		label.text = "GAME OVER\nDu hast verloren."
		input.visible = false
