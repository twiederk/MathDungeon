class_name SubtractionExerciseGenerator

var max_number: int = 100

func _init(_max_number: int = 100):
	max_number = _max_number

func create_exercise() -> Exercise:
	var minuend = (randi() + 1) % max_number
	var subtrahend = randi() % minuend
	var result = minuend - subtrahend
	var question = "Was ist das Ergebnis von %s - %s?" % [str(minuend), str(subtrahend)]
	return Exercise.new(question, str(result))
	
