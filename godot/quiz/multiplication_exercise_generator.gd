class_name MultiplicationExerciseGenerator


func create_exercise(max_number: int = 10) -> Exercise:
	var factorA = randi_range(0, max_number)
	var factorB = randi_range(0, max_number)
	var result = factorA * factorB
	var question = "Was ist das Ergebnis von %s * %s?" % [str(factorA), str(factorB)]
	return Exercise.new(question, str(result))
