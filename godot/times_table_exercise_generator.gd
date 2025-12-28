class_name TimesTableExerciseGenerator


var times_tables: Array = []


func _init():
	times_tables.clear()
	
	for multiplier in range(1, 11):
		var sequence_string = ""
		for i in range(1, 11):
			var product = multiplier * i
			sequence_string += str(product)
			if i < 10:
				sequence_string += " "
		times_tables.append(sequence_string)


func create_exercise() -> Exercise:
	var table_index = randi() % times_tables.size()
	var result = times_tables[table_index]
	var multiplier = table_index + 1
	var question = "Wie lautet die %ser Reihe des kleinen Einmaleins?" % str(multiplier)
	return Exercise.new(question, result)