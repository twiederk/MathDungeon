extends GutTest

var english_vocabulary_exercise_generator: EnglishVocabularyExerciseGenerator = null


func before_each():
	english_vocabulary_exercise_generator = EnglishVocabularyExerciseGenerator.new()


func after_each():
	english_vocabulary_exercise_generator = null


func test_create_exercise():
	# arrange
	seed(1)
	
	# act
	var exercise = english_vocabulary_exercise_generator.create_exercise()
	
	# assert
	assert_eq(exercise.question, "Wie lautet das englische Wort für: Hut?")
	assert_eq(exercise.result, "hat")
