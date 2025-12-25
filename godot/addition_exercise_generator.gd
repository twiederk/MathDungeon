class_name AdditionExerciseGenerator

var max := 1000

func _init(_max := 1000):
	max = _max
	randomize()

func create_exercise() -> Exercise:
	var summand_a = randi() % max
	var summand_b = randi() % (max - summand_a)
	var result = summand_a + summand_b
	return Exercise.new(summand_a, summand_b, "+", result)
	
