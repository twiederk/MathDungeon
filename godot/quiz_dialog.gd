class_name QuizDialog
extends Control

@onready var label: Label = $CenterContainer/VBoxContainer/Label
@onready var input: LineEdit = $CenterContainer/VBoxContainer/LineEdit

var enemy: Enemy = null
var exercise: Exercise


func open_for(my_enemy: Enemy) -> void:
	enemy = my_enemy

	exercise = _create_exercise()
	label.text = _question()
	input.text = ""
	visible = true

	input.grab_focus()
	get_tree().paused = true


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
		enemy.hit_points -= 1
		if enemy.hit_points > 0:
			exercise = _create_exercise()
			label.text = "Richtig!!!\n" + _question()
			input.text = ""
		else:
			enemy.queue_free()
			_close_dialog()
	else:
		label.text = "Nicht ganz. Versuch es nochmal:\n" + _question()
		input.text = ""


func _close_dialog() -> void:
	visible = false
	get_tree().paused = false
	enemy = null
	exercise = null


func _question() -> String:
	return "Was ist das Ergebnis von: %s %s %s?" % [str(exercise.argument1), exercise.operator, str(exercise.argument2)]
