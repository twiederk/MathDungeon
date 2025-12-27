class_name DivisionExerciseGenerator

var max_number: int = 100
var exercises: Array = []

func _init(_max_number: int = 100):
	max_number = _max_number

	exercises.clear()
	for divisor in range(1, 11):
		for quotient in range(1, 11):
			var dividend = divisor * quotient
			exercises.append(Exercise.new(dividend, divisor, ":", quotient))

func create_exercise() -> Exercise:
	var idx = randi() % exercises.size()
	return exercises[idx]
