class_name QuizDialog
extends Control

@onready var label: Label = $Panel/Label
@onready var input: LineEdit = $Panel/LineEdit
@onready var button: Button = $Panel/Button

var current_enemy: Node = null

func _ready() -> void:
	visible = false
	button.pressed.connect(_on_submit)
	input.text_submitted.connect(_on_text_submitted)

func open_for(enemy: Node) -> void:
	current_enemy = enemy
	label.text = "Was ist 1 + 1?"
	input.text = ""
	visible = true
	input.grab_focus()

func _on_submit() -> void:
	_check_answer()

func _on_text_submitted(_text: String) -> void:
	_check_answer()

func _check_answer() -> void:
	var answer := input.text.strip_edges()
	if answer == "2":
		if is_instance_valid(current_enemy):
			current_enemy.queue_free()  # Gegner entfernen
		visible = false
	else:
		# Feedback bei falscher Antwort (optional: Sound, Farbe, etc.)
		label.text = "Nicht ganz. Versuch es nochmal: Was ist 1 + 1?"
		input.select_all()
		input.grab_focus()
