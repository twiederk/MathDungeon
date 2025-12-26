class_name QuizDialog
extends Control

@onready var label: Label = $CenterContainer/VBoxContainer/Label
@onready var input: LineEdit = $CenterContainer/VBoxContainer/LineEdit
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var answer_timer = $AnswerTimer

var enemy: Enemy = null
var exercise: Exercise
var time_remaining: float


func open_for(my_enemy: Enemy) -> void:
	enemy = my_enemy

	exercise = _create_exercise()
	label.text = _question()
	input.text = ""
	visible = true

	_setup_progress_bar()

	input.grab_focus()
	get_tree().paused = true


func _setup_progress_bar() -> void:
	if enemy.stats.time_limit == -1:
		progress_bar.visible = false
	else:
		time_remaining = enemy.stats.time_limit
		progress_bar.visible = true
		progress_bar.value = 0
		progress_bar.max_value = enemy.stats.time_limit
		answer_timer.start()


func _on_AnswerTimer_timeout() -> void:
	progress_bar.value = time_remaining
	_answer_incorrect()


func _create_exercise() -> Exercise:
	var arithmetic = enemy.stats.arithmetic.pick_random()
	match arithmetic:
		EnemyStats.ArithmeticType.ADDITION:
			return AdditionExerciseGenerator.new(enemy.stats.max_number).create_exercise()
		EnemyStats.ArithmeticType.SUBSTRACTION:
			return SubtractionExerciseGenerator.new(enemy.stats.max_number).create_exercise()
		EnemyStats.ArithmeticType.MULTIPLICATION:
			return MultiplicationExerciseGenerator.new().create_exercise()
	return AdditionExerciseGenerator.new(enemy.stats.max_number).create_exercise()


func _on_text_submitted(text: String) -> void:
	var answer: int = text.strip_edges().to_int()
	_check_answer(answer)


func _on_button_pressed() -> void:
	var answer: int = input.text.strip_edges().to_int()
	_check_answer(answer)


func _check_answer(answer: int) -> void:
	if answer == exercise.result:
		_answer_correct()
	else:
		_answer_incorrect()


func _answer_correct() -> void:
	enemy.hit_points -= PlayerStats.damage
	if enemy.hit_points > 0:
		exercise = _create_exercise()
		label.text = "Richtig!!!\n" + _question()
		input.text = ""
	else:
		enemy.queue_free()
		_close_dialog()


func _answer_incorrect() -> void:
	PlayerStats.hit_points -= enemy.stats.damage
	if PlayerStats.hit_points > 0:
		label.text = "Nicht ganz. Versuch es nochmal:\n" + _question()
		input.text = ""
	else:
		label.text = "Du hast alle Lebenspunkte verloren.\nDu hast verloren."
		input.text = ""


func _close_dialog() -> void:
	visible = false
	get_tree().paused = false
	enemy = null
	exercise = null


func _question() -> String:
	return "Was ist das Ergebnis von: %s %s %s?" % [str(exercise.argument1), exercise.operator, str(exercise.argument2)]
