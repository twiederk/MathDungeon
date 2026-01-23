class_name SubtractionExerciseGenerator


func create_exercise(max_number: int = 100) -> Exercise:
	var minuend = randi_range(1, max_number)
	var subtrahend = randi_range(0, minuend)
	var result = minuend - subtrahend
	var question = "Was ist das Ergebnis von %s - %s?" % [str(minuend), str(subtrahend)]
	return Exercise.new(question, str(result))
	
