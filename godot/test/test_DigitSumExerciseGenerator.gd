extends GutTest

var digit_sum_exercise_generator: DigitSumExerciseGenerator = null


func before_each():
	digit_sum_exercise_generator = DigitSumExerciseGenerator.new()


func after_each():
	digit_sum_exercise_generator = null


func test_create_exercise():
	# arrange
	seed(1)
	
	# act
	var exercise = digit_sum_exercise_generator.create_exercise()
	
	# assert
	assert_not_null(exercise, "Exercise should not be null")
	assert_eq(exercise.question, "Was ist die Quersumme von 568?")
	assert_eq(exercise.result, "19")
