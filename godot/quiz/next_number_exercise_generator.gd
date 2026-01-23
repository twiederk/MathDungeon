class_name NextNumberExerciseGenerator

var max_number: int = 100

func _init(_max_number: int = 100):
	max_number = _max_number

func create_exercise() -> Exercise:
	var number = randi_range(0, max_number)
	var result = number + 1
	var question = "Was ist die nächste Zahl nach %s?" % [str(number)]
	return Exercise.new(question, str(result))
	
