class_name MultiplicationExerciseGenerator

func create_exercise() -> Exercise:
	var factorA = randi() % 11
	var factorB = randi() % 11
	var result = factorA * factorB
	var question = "Was ist das Ergebnis von %s * %s?" % [str(factorA), str(factorB)]
	return Exercise.new(question, str(result))
