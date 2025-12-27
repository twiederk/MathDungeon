class_name DivisionExerciseGenerator

var max_number: int = 100

func _init(_max_number: int = 100):
	max_number = _max_number

func create_exercise() -> Exercise:
	# Choose a divisor between 1 and 10 to avoid large divisors
	var divisor = randi() % 10 + 1
	# Ensure quotient is at least 1 and dividend <= max_number
	var max_quotient = max(1, int(max_number / divisor))
	var quotient = randi() % max_quotient + 1
	var dividend = divisor * quotient
	return Exercise.new(dividend, divisor, "/", quotient)
