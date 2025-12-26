class_name MultiplicationExerciseGenerator

func create_exercise() -> Exercise:
	var factorA = randi() % 10 + 1
	var factorB = randi() % 10 + 1
	var result = factorA * factorB
	return Exercise.new(factorA, factorB, "*", result)
