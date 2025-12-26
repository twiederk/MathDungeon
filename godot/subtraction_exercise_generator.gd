class_name SubtractionExerciseGenerator

var max_number: int = 100

func _init(_max_number: int = 100):
	max_number = _max_number

func create_exercise() -> Exercise:
	var minuend = randi() % max_number
	var subtrahend = randi() % minuend
	var result = minuend - subtrahend
	return Exercise.new(minuend, subtrahend, "-", result)
	
