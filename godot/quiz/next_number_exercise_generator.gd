class_name NextNumberExerciseGenerator


func create_exercise(max_number: int = 100) -> Exercise:
	var number = randi_range(0, max_number)
	var result = number + 1
	var question = "Was ist die nächste Zahl nach %s?" % [str(number)]
	return Exercise.new(question, str(result))
	
