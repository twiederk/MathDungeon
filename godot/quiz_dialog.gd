class_name QuizDialog
extends Control

@onready var label: Label = $CenterContainer/VBoxContainer/Label
@onready var input: LineEdit = $CenterContainer/VBoxContainer/LineEdit

var current_enemy: Enemy = null
var addition_exercise_generator: AdditionExerciseGenerator = AdditionExerciseGenerator.new(100)
var exercise: Exercise


func open_for(enemy: Enemy) -> void:
	current_enemy = enemy

	exercise = addition_exercise_generator.create_exercise()
	label.text = _question()
	input.text = ""
	visible = true

	input.grab_focus()

	get_tree().paused = true


func _on_text_submitted(_text: String) -> void:
	var answer: int = input.text.strip_edges().to_int()
	_check_answer(answer)


func _check_answer(answer: int) -> void:
	if answer == exercise.result:
		current_enemy.queue_free()
		_close_dialog()
	else:
		label.text = "Nicht ganz. Versuch es nochmal:\n" + _question()
		input.text = ""


func _close_dialog() -> void:
	visible = false
	get_tree().paused = false
	current_enemy = null
	exercise = null


func _question() -> String:
	return "Was ist das Ergebnis von: %s %s %s?" % [str(exercise.argument1), exercise.operator, str(exercise.argument2)]
