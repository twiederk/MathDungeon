class_name NumberRiddleExerciseGenerator

var riddle_types: Array[String] = [
	"next_ten",
	"half_minus",
	"digit_relation_3digit",
	"half_of",
	"next_after_max_3digit",
	"digit_relation_large",
	"between_same_digits",
	"before_1000",
	"tens_ones_hundreds_relation",
	"between_single_digits"
]


func create_exercise() -> Exercise:
	var riddle_type = riddle_types[randi() % riddle_types.size()]
	
	match riddle_type:
		"next_ten":
			return _create_next_ten_riddle()
		"half_minus":
			return _create_half_minus_riddle()
		"digit_relation_3digit":
			return _create_digit_relation_3digit_riddle()
		"half_of":
			return _create_half_of_riddle()
		"next_after_max_3digit":
			return _create_next_after_max_3digit_riddle()
		"digit_relation_large":
			return _create_digit_relation_large_riddle()
		"between_same_digits":
			return _create_between_same_digits_riddle()
		"before_1000":
			return _create_before_1000_riddle()
		"tens_ones_hundreds_relation":
			return _create_tens_ones_hundreds_relation_riddle()
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


func _create_digit_relation_3digit_riddle() -> Exercise:
	# Generate all valid numbers with pattern: ones = 2 * tens, hundreds = tens - 1
	var results = []
	for t in range(2, 5):  # tens from 2-4 to keep ones single digit
		var h = t - 1
		var o = t * 2
		if h > 0 and o <= 9:
			var number = h * 100 + t * 10 + o
			if number < 400:
				results.append(str(number))
	
	var question = "Meine dreistellige Zahl ist kleiner als 400. Der Einer ist doppelt so groß wie der Zehner. Der Hunderter ist um 1 kleiner als der Zehner."
	return Exercise.new(question, " ".join(results))


func _create_half_of_riddle() -> Exercise:
	var base_number = randi_range(200, 500) * 2  # Ensure even number
	@warning_ignore("integer_division")
	var result = base_number / 2
	var question = "Meine Zahl ist halb so groß wie %d." % base_number
	return Exercise.new(question, str(result))


func _create_next_after_max_3digit_riddle() -> Exercise:
	var question = "Meine Zahl ist um eins größer als die größte, dreistellige Zahl."
	return Exercise.new(question, "1000")


func _create_digit_relation_large_riddle() -> Exercise:
	# Generate number > 700 where: ones = hundreds/2, tens = hundreds + 1
	var hundreds = randi_range(8, 9)  # 8 or 9 to be > 700
	var tens = hundreds + 1
	@warning_ignore("integer_division")
	var ones = hundreds / 2
	
	if tens <= 9 and ones == int(ones):  # tens must be single digit, ones must be whole number
		var number = hundreds * 100 + tens * 10 + int(ones)
		var question = "Meine Zahl ist größer als 700. Der Einer ist nur halb so groß wie der Hunderter. Der Zehner ist um 1 größer als der Hunderter."
		return Exercise.new(question, str(number))
	else:
		return _create_next_ten_riddle()  # Fallback


func _create_between_same_digits_riddle() -> Exercise:
	var question = "Meine Zahl liegt zwischen 400 und 600. Sie hat drei gleiche Ziffern."
	return Exercise.new(question, "444 555")


func _create_before_1000_riddle() -> Exercise:
	var question = "Meine Zahl ist um 1 kleiner als 1000."
	return Exercise.new(question, "999")


func _create_tens_ones_hundreds_relation_riddle() -> Exercise:
	var tens_digit = 4
	var ones_digit = tens_digit * 2  # 8
	@warning_ignore("integer_division")
	var hundreds_digit = tens_digit / 2  # 2
	var number = hundreds_digit * 100 + tens_digit * 10 + ones_digit
	var question = "Meine Zahl hat 4 Zehner und doppelt so viele Einer. Der Hunderter ist halb so groß wie der Zehner."
	return Exercise.new(question, str(number))


func _create_between_single_digits_riddle() -> Exercise:
	var number = 811  # Only valid answer between 800-900 with one ten and one one
	var question = "Meine Zahl liegt zwischen 800 und 900. Sie hat nur einen Einer und einen Zehner."
	return Exercise.new(question, str(number))