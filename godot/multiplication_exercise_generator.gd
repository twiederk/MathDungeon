class_name MultiplicationExerciseGenerator

func create_exercise() -> Exercise:
	var factorA = randi() % 10 + 1
	var factorB = randi() % 10 + 1
	var result = factorA * factorB
	var question = "Was ist das Ergebnis von %s * %s?" % [str(factorA), str(factorB)]
	return Exercise.new(factorA, factorB, "*", str(result), question)
