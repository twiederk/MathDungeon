class_name QuizDialog
extends Control

@onready var label: Label = $CenterContainer/VBoxContainer/Label
@onready var input: LineEdit = $CenterContainer/VBoxContainer/LineEdit
@onready var button: Button = $CenterContainer/VBoxContainer/Button

var current_enemy: Node = null
var addition_exercise_generator := AdditionExerciseGenerator.new(100)
var exercise: Exercise


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	button.pressed.connect(_on_submit)
	input.text_submitted.connect(_on_text_submitted)


func open_for(enemy: Node) -> void:
	current_enemy = enemy

	exercise = addition_exercise_generator.create_exercise()
	label.text = _question()
	input.text = ""
	visible = true

	get_tree().paused = true

	input.grab_focus()


func _on_submit() -> void:
	_check_answer()


func _on_text_submitted(_text: String) -> void:
	_check_answer()


func _check_answer() -> void:
	var user_answer: int = _norm(input.text).to_int()

	if user_answer == exercise.result:
		if is_instance_valid(current_enemy):
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


func _norm(s: String) -> String:
	return s.strip_edges().to_lower()
	
	
func _question() -> String:
	# var message = "Name: %s %s" % [first_name, last_name]
	return "Was ist das Ergebnis von: %s %s %s?" % [str(exercise.argument1), exercise.operator, str(exercise.argument2)]
