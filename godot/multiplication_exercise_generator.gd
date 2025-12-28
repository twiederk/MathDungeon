class_name MultiplicationExerciseGenerator

func create_exercise() -> Exercise:
	var factorA = randi_range(0, 10)
	var factorB = randi_range(0, 10)
	var result = factorA * factorB
	var question = "Was ist das Ergebnis von %s * %s?" % [str(factorA), str(factorB)]
	return Exercise.new(question, str(result))
