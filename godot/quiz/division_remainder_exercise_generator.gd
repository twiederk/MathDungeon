class_name DivisionRemainderExerciseGenerator


var exercises: Array = []


func _init():
	exercises.clear()
	for divisor in range(1, 11):
		var max_dividend = divisor * 10
		for dividend in range(1, max_dividend + 1):
			@warning_ignore("integer_division")
			var quotient = int(dividend / divisor)
			var remainder = dividend % divisor
			var question = "Was ist das Ergebnis von %s : %s?" % [str(dividend), str(divisor)]
			var answer: String
			if remainder == 0:
				answer = str(quotient)
			else:
				answer = "%s R%s" % [str(quotient), str(remainder)]
			exercises.append(Exercise.new(question, answer))


func create_exercise() -> Exercise:
	var idx = randi() % exercises.size()
	return exercises[idx]
