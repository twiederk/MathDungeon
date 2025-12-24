class_name QuizDialog
extends Control

const QUESTIONS: Array[Dictionary] = [
	{"id": "math_1", "question": "Was ist 1 + 1?", "answers": ["2"]},
	{"id": "math_2", "question": "Was ist 27 + 54?", "answers": ["81"]},
	{"id": "math_3", "question": "Was ist 42 - 17?", "answers": ["25"]},
	{"id": "math_4", "question": "Was ist 3 × 6?", "answers": ["18"]}
]

@onready var label: Label = $Panel/Label
@onready var input: LineEdit = $Panel/LineEdit
@onready var button: Button = $Panel/Button

var current_enemy: Node = null
var current_question: Dictionary = {}
var question_pool: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	# Der Dialog soll Eingaben verarbeiten, auch wenn das Spiel pausiert ist
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	# (Optional) Panel schluckt Maus-Ereignisse komplett
	$Panel.mouse_filter = Control.MOUSE_FILTER_STOP

	button.pressed.connect(_on_submit)
	input.text_submitted.connect(_on_text_submitted)

	# Zufall initialisieren & Fragenpool vorbereiten
	rng.randomize()
	_reset_and_shuffle_pool()

func open_for(enemy: Node) -> void:
	current_enemy = enemy
	_pick_next_question()

	# UI setzen
	label.text = current_question.get("question", "Frage fehlt")
	input.text = ""
	input.placeholder_text = "Antwort eingeben…"
	visible = true

	# Alles pausieren
	get_tree().paused = true

	input.grab_focus()

func _on_submit() -> void:
	_check_answer()

func _on_text_submitted(_text: String) -> void:
	_check_answer()

func _check_answer() -> void:
	var user_answer := _norm(input.text)
	var accepted: Array = []
	if current_question.has("answers"):
		for a in current_question["answers"]:
			accepted.append(_norm(String(a)))

	if accepted.has(user_answer):
		# Richtige Antwort → Gegner entfernen, Dialog schließen
		if is_instance_valid(current_enemy):
			current_enemy.queue_free()
		_close_dialog()
	else:
		# Feedback bei falscher Antwort, gleiche Frage erneut
		label.text = "Nicht ganz. Versuch es nochmal:\n" + current_question.get("question", "Frage fehlt")
		input.select_all()
		input.grab_focus()

func _close_dialog() -> void:
	visible = false
	# Spiel fortsetzen
	get_tree().paused = false
	current_enemy = null
	current_question = {}

func _norm(s: String) -> String:
	# trim + lowercase (optional: hier könntest du Umlaute normalisieren)
	return s.strip_edges().to_lower()

func _reset_and_shuffle_pool() -> void:
	question_pool = QUESTIONS.duplicate()
	question_pool.shuffle()  # Godot 4: Array.shuffle()

func _pick_next_question() -> void:
	if question_pool.is_empty():
		_reset_and_shuffle_pool()
	# Nächste Frage ziehen (ohne Wiederholung): vom Ende abpoppen
	current_question = question_pool.pop_back()
