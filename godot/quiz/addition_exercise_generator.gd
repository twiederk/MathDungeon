class_name AdditionExerciseGenerator


func create_exercise(max_number: int = 100) -> Exercise:
	var summand_a = randi_range(0, max_number)
	var summand_b = randi_range(0, max_number - summand_a)
	var result = summand_a + summand_b
	var question = "Was ist das Ergebnis von %s + %s?" % [str(summand_a), str(summand_b)]
	return Exercise.new(question, str(result))
	
