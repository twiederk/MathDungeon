class_name DivisionExerciseGenerator


const MIN_DIVISOR := 1
const MAX_DIVISOR := 10


func create_exercise(max_dividend: int = 100) -> Exercise:
	var divisor = randi_range(MIN_DIVISOR, MAX_DIVISOR)
	@warning_ignore("integer_division")
	var max_quotient = maxi(1, int(max_dividend / divisor))
	var quotient = randi_range(1, max_quotient)
	var dividend = divisor * quotient
	var question = "Was ist das Ergebnis von %s : %s?" % [str(dividend), str(divisor)]
	return Exercise.new(question, str(quotient))
