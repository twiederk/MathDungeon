class_name NumberRiddleExerciseGenerator

var riddle_types: Array[String] = [
	"next_ten",
	"half_minus",
	"half_of",
	"next_after_max_3digit",
	"between_same_digits",
	"before_1000",
	"between_single_digits"
]


func create_exercise() -> Exercise:
	var riddle_type = riddle_types[randi() % riddle_types.size()]
	
	match riddle_type:
		"next_ten":
			return _create_next_ten_riddle()
		"half_minus":
			return _create_half_minus_riddle()
		"half_of":
			return _create_half_of_riddle()
		"next_after_max_3digit":
			return _create_next_after_max_3digit_riddle()
		"between_same_digits":
			return _create_between_same_digits_riddle()
		"before_1000":
			return _create_before_1000_riddle()
		"between_single_digits":
			return _create_between_single_digits_riddle()
		_:
			return _create_next_ten_riddle()


func _create_next_ten_riddle() -> Exercise:
	var base_number = randi_range(100, 990)
	@warning_ignore("integer_division")
	var next_ten = ((base_number / 10) + 1) * 10
	var question = "Meine Zahl ist die nächste Zehnerzahl die größer ist als %d." % base_number
	return Exercise.new(question, str(next_ten))


func _create_half_minus_riddle() -> Exercise:
	var base_number = randi_range(100, 300) * 2  # Ensure even number for clean half
	var minus_value = randi_range(2, 10)
	@warning_ignore("integer_division")
	var result = (base_number / 2) - minus_value
	var question = "Meine Zahl ist um %d kleiner als die Hälfte von %d." % [minus_value, base_number]
	return Exercise.new(question, str(result))


func _create_half_of_riddle() -> Exercise:
	var base_number = randi_range(200, 500) * 2  # Ensure even number
	@warning_ignore("integer_division")
	var result = base_number / 2
	var question = "Meine Zahl ist halb so groß wie %d." % base_number
	return Exercise.new(question, str(result))


func _create_next_after_max_3digit_riddle() -> Exercise:
	var digit_type = randi_range(1, 3)  # Randomly choose 1, 2, or 3 digits
	
	match digit_type:
		1:
			var question = "Meine Zahl ist um eins größer als die größte, einstellige Zahl."
			return Exercise.new(question, "10")
		2:
			var question = "Meine Zahl ist um eins größer als die größte, zweistellige Zahl."
			return Exercise.new(question, "100")
		_:  # 3 digits (default)
			var question = "Meine Zahl ist um eins größer als die größte, dreistellige Zahl."
			return Exercise.new(question, "1000")


func _create_between_same_digits_riddle() -> Exercise:
	# Define ranges where only one solution with three same digits exists
	var ranges = [
		{"min": 100, "max": 200, "answer": "111"},
		{"min": 200, "max": 300, "answer": "222"},
		{"min": 300, "max": 400, "answer": "333"},
		{"min": 400, "max": 500, "answer": "444"},
		{"min": 500, "max": 600, "answer": "555"},
		{"min": 600, "max": 700, "answer": "666"},
		{"min": 700, "max": 800, "answer": "777"},
		{"min": 800, "max": 900, "answer": "888"},
		{"min": 900, "max": 1000, "answer": "999"}
	]
	
	var selected_range = ranges[randi() % ranges.size()]
	var question = "Meine Zahl liegt zwischen %d und %d. Sie hat drei gleiche Ziffern." % [selected_range.min, selected_range.max]
	return Exercise.new(question, selected_range.answer)


func _create_before_1000_riddle() -> Exercise:
	var targets = [
		{"number": 10, "answer": "9"},
		{"number": 100, "answer": "99"},
		{"number": 1000, "answer": "999"}
	]
	
	var selected_target = targets[randi() % targets.size()]
	var question = "Meine Zahl ist um 1 kleiner als %d." % selected_target.number
	return Exercise.new(question, selected_target.answer)


func _create_between_single_digits_riddle() -> Exercise:
	var number = 811  # Only valid answer between 800-900 with one ten and one one
	var question = "Meine Zahl liegt zwischen 800 und 900. Sie hat nur einen Einer und einen Zehner."
	return Exercise.new(question, str(number))