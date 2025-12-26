class_name MultiplicationExerciseGenerator

func create_exercise() -> Exercise:
	var factorA = randi() % 11
	var factorB = randi() % 11
	var result = factorA - factorB
	return Exercise.new(factorA, factorB, "*", result)
