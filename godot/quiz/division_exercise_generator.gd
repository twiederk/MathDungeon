class_name DivisionExerciseGenerator


var exercises: Array = []


func _init():
	exercises.clear()
	for divisor in range(1, 11):
		for quotient in range(1, 11):
			var dividend = divisor * quotient
			var question = "Was ist das Ergebnis von %s : %s?" % [str(dividend), str(divisor)]
			exercises.append(Exercise.new(question, str(quotient)))


func create_exercise() -> Exercise:
	var idx = randi() % exercises.size()
	return exercises[idx]
