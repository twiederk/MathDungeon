extends GutTest

var next_number_exercise_generator: NextNumberExerciseGenerator = null


func before_each():
	next_number_exercise_generator = NextNumberExerciseGenerator.new()


func after_each():
	next_number_exercise_generator = null


func test_create_exercise():
	# arrange
	seed(1)
	
	# act
	var exercise = next_number_exercise_generator.create_exercise()
	
	# assert
	assert_not_null(exercise, "Exercise should not be null")
	assert_eq(exercise.question, "Was ist die nächste Zahl nach 88?")
	assert_eq(exercise.result, "89")
