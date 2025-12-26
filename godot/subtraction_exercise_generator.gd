class_name SubtractionExerciseGenerator

var max_number: int = 100

func _init(_max_number: int = 100):
	max_number = _max_number
	randomize()

func create_exercise() -> Exercise:
	var summand_a = randi() % max_number
	var summand_b = randi() % (max_number - summand_a)
	var result = summand_a + summand_b
	return Exercise.new(summand_a, summand_b, "+", result)
	
