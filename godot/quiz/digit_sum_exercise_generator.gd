class_name DigitSumExerciseGenerator

var min_digits: int = 2
var max_digits: int = 5


func _init(_min_digits: int = 2, _max_digits: int = 5):
	min_digits = _min_digits
	max_digits = _max_digits


func create_exercise() -> Exercise:
	var number_of_digits = randi_range(min_digits, max_digits)
	var number = _generate_number_with_digits(number_of_digits)
	var digit_sum = _calculate_digit_sum(number)
	var question = "Was ist die Quersumme von %s?" % str(number)
	return Exercise.new(question, str(digit_sum))


func _generate_number_with_digits(digits: int) -> int:
	var min_value = int(pow(10, digits - 1))
	var max_value = int(pow(10, digits) - 1)
	return randi_range(min_value, max_value)


func _calculate_digit_sum(number: int) -> int:
	var digit_sum = 0
	while number > 0:
		digit_sum += number % 10
		@warning_ignore("integer_division")
		number = number / 10

	return digit_sum
