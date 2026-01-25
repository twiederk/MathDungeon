class_name QuizDialog
extends Control


var addition_exercise_generator = AdditionExerciseGenerator.new()
var subtraction_exercise_generator = SubtractionExerciseGenerator.new()
var multiplication_exercise_generator = MultiplicationExerciseGenerator.new()
var division_exercise_generator = DivisionExerciseGenerator.new()
var division_remainder_exercise_generator = DivisionRemainderExerciseGenerator.new()
var times_table_exercise_generator = TimesTableExerciseGenerator.new()
var digit_sum_exercise_generator = DigitSumExerciseGenerator.new()
var number_riddle_exercise_generator = NumberRiddleExerciseGenerator.new()
var next_number_exercise_generator = NextNumberExerciseGenerator.new()
var enemy: Enemy = null
var exercise: Exercise = null


@onready var enemy_stats_sheet: StatsSheet = $EnemyStatsSheet
@onready var question_label: Label = $CenterContainer/VBoxContainer/QuestionLabel
@onready var answer_line_edit: LineEdit = $CenterContainer/VBoxContainer/AnswerLineEdit
@onready var start_gui_button: Button = $CenterContainer/VBoxContainer/StartGuiButton
@onready var name_entry_button = $CenterContainer/VBoxContainer/NameEntryButton
@onready var time_limit_progress_bar: ProgressBar = $CenterContainer/VBoxContainer/TimelimitProgressBar
@onready var answer_timer = $AnswerTimer
@onready var progress_timer = $ProgressTimer


func open_for(my_enemy: Enemy) -> void:
	enemy = my_enemy
	_setup_exercise()
	_setup_time_limit_progress_bar()
	_setup_enemy_stats_sheet()
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


func _setup_enemy_stats_sheet() -> void:
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy_stats_sheet.update_stats(enemy.hit_points, enemy.stats.max_hit_points, enemy.stats.damage, enemy.stats.armor)



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
			return addition_exercise_generator.create_exercise(enemy.stats.max_number)
		EnemyStats.ArithmeticType.SUBSTRACTION:
			return subtraction_exercise_generator.create_exercise(enemy.stats.max_number)
		EnemyStats.ArithmeticType.MULTIPLICATION:
			return multiplication_exercise_generator.create_exercise()
		EnemyStats.ArithmeticType.DIVISION:
			return division_exercise_generator.create_exercise()
		EnemyStats.ArithmeticType.DIVISION_REMAINDER:
			return division_remainder_exercise_generator.create_exercise()
		EnemyStats.ArithmeticType.TIMES_TABLE:
			return times_table_exercise_generator.create_exercise()
		EnemyStats.ArithmeticType.DIGIT_SUM:
			return digit_sum_exercise_generator.create_exercise(enemy.stats.max_number)
		EnemyStats.ArithmeticType.NUMBER_RIDDLE:
			return number_riddle_exercise_generator.create_exercise()
		EnemyStats.ArithmeticType.NEXT_NUMBER:
			return next_number_exercise_generator.create_exercise(enemy.stats.max_number)
	return addition_exercise_generator.create_exercise(enemy.stats.max_number)


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
	var enemy_hit_points = enemy.hurt(PlayerStats.get_total_damage())
	if enemy_hit_points > 0:
		exercise = _create_exercise()
		question_label.text = "Richtig!!!\n" + exercise.question
		answer_line_edit.text = ""
		if enemy.has_time_limit():
			_start_timers()
	else:
		PlayerStats.add_score(enemy.stats.get_score())
		if enemy.has_time_limit():
			answer_timer.stop()
			progress_timer.stop()
		if enemy.stats.name == "Enderdragon":
			get_tree().call_deferred("change_scene_to_file", "res://gui/victory_dialog.tscn")
		enemy.queue_free()
		_close_dialog()


func _answer_incorrect() -> void:
	var player_hit_points = PlayerStats.hurt(enemy.stats.damage)
	if player_hit_points > 0:
		question_label.text = "Nicht ganz. Versuch es nochmal:\n" + exercise.question
		answer_line_edit.text = ""
	else:
		_game_over()


func _game_over() -> void:
	var button : Button
	var message: String
	if HighscoreManager.is_highscore(PlayerStats.current_score):
		message = "Du hast alle Lebenspunkte verloren.\nDu hast einen neuen Bestenwert erspielt!!!"
		button = name_entry_button
	else: 
		message = "Du hast alle Lebenspunkte verloren.\nDu hast verloren."
		button = start_gui_button
	button.visible = true
	button.grab_focus()
	question_label.text = message
	answer_line_edit.text = ""
	answer_line_edit.visible = false
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
	var player_hit_points = PlayerStats.hurt(enemy.stats.damage)
	if player_hit_points > 0:
		exercise = _create_exercise()
		question_label.text = "*** Zeitlimit überschritten ***\n" + exercise.question
		answer_line_edit.text = ""
		_start_timers()
	else:
		question_label.text = "GAME OVER\nDu hast verloren."
		answer_line_edit.visible = false


func _on_enemy_health_changed() -> void:
	enemy_stats_sheet.update_health_only(enemy.hit_points)


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://gui/start_gui.tscn")


func _on_name_entry_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://gui/name_entry_dialog.tscn")
