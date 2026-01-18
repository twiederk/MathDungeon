extends GutTest

var number_riddle_exercise_generator: NumberRiddleExerciseGenerator = null


func before_each():
	seed(1)
	number_riddle_exercise_generator = NumberRiddleExerciseGenerator.new()


func after_each():
	number_riddle_exercise_generator = null


func test_create_exercise_not_null():
	# act
	var exercise = number_riddle_exercise_generator.create_exercise()
	
	# assert
	assert_not_null(exercise, "Exercise should not be null")
	assert_eq(exercise.question, "Meine Zahl liegt zwischen 100 und 200. Sie hat nur einen Einer und einen Zehner.")
	assert_eq(exercise.result, "111")


func test_next_ten_riddle():
	# act
	var exercise = number_riddle_exercise_generator._create_next_ten_riddle()
	
	# assert
	assert_not_null(exercise, "Exercise should not be null")
	assert_eq(exercise.question, "Meine Zahl ist die nächste Zehnerzahl die größer ist als 160.")
	assert_eq(exercise.result, "170")


func test_half_minus_riddle():
	# act
	var exercise = number_riddle_exercise_generator._create_half_minus_riddle()
	
	# assert
	assert_not_null(exercise, "Exercise should not be null")
	assert_eq(exercise.question, "Meine Zahl ist um 2 kleiner als die Hälfte von 248.")
	assert_eq(exercise.result, "122")


func test_half_of_riddle():
	# act
	var exercise = number_riddle_exercise_generator._create_half_of_riddle()
	
	# assert
	assert_not_null(exercise, "Exercise should not be null")
	assert_eq(exercise.question, "Meine Zahl ist halb so groß wie 468.")
	assert_eq(exercise.result, "234")


func test_next_after_max_3digit_riddle():
	# act
	var exercise = number_riddle_exercise_generator._create_next_after_max_3digit_riddle()
	
	# assert
	assert_not_null(exercise)
	assert_eq(exercise.question, "Meine Zahl ist um eins größer als die größte, einstellige Zahl.")
	assert_eq(exercise.result, "10")


func test_before_1000_riddle():
	# act
	var exercise = number_riddle_exercise_generator._create_before_1000_riddle()
	
	# assert
	assert_not_null(exercise)
	assert_eq(exercise.question, "Meine Zahl ist um 1 kleiner als 10.")
	assert_eq(exercise.result, "9")


func test_between_single_digits_riddle():	
	# act
	var exercise = number_riddle_exercise_generator._create_between_single_digits_riddle()
	
	# assert
	assert_not_null(exercise)
	assert_eq(exercise.question, "Meine Zahl liegt zwischen 700 und 800. Sie hat nur einen Einer und einen Zehner.")
	assert_eq(exercise.result, "711")


func test_between_same_digits_riddle():
	# act
	var exercise = number_riddle_exercise_generator._create_between_same_digits_riddle()
	
	# assert
	assert_not_null(exercise)
	assert_eq(exercise.question, "Meine Zahl liegt zwischen 700 und 800. Sie hat drei gleiche Ziffern.")
	assert_eq(exercise.result, "777")
