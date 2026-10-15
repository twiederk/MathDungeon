class_name DivisionExerciseGenerator


const MIN_DIVISOR := 1

var exercises: Array = []


func _init(max_dividend: int = 100, max_divisor: int = 10):
	exercises.clear()
	for divisor in range(MIN_DIVISOR, max_divisor + 1):
		@warning_ignore("integer_division")
		var max_quotient = int(max_dividend / divisor)
		for quotient in range(1, max_quotient + 1):
			var dividend = divisor * quotient
			var question = "Was ist das Ergebnis von %s : %s?" % [str(dividend), str(divisor)]
			exercises.append(Exercise.new(question, str(quotient)))


func create_exercise() -> Exercise:
	var idx = randi() % exercises.size()
	return exercises[idx]
