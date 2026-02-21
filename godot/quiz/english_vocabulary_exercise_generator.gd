class_name EnglishVocabularyExerciseGenerator


enum DictionaryType {
	ALL,
	COLOR
}


var dictionary_type: DictionaryType


var vocabulary: Array = []


func _init(dict_type: DictionaryType = DictionaryType.ALL) -> void:
	dictionary_type = dict_type
	_load_dictionary()


func _load_dictionary() -> void:
	var dictionary_file_path: String
	
	match dictionary_type:
		DictionaryType.ALL:
			dictionary_file_path = "res://quiz/dictionary.txt"
		DictionaryType.COLOR:
			dictionary_file_path = "res://quiz/dictionary_colors.txt"
	
	var file = FileAccess.open(dictionary_file_path, FileAccess.READ)
	
	if file == null:
		push_error("Failed to load dictionary file at: %s" % dictionary_file_path)
		return
	
	while file.get_position() < file.get_length():
		var line = file.get_line()
		var parts = line.split(",")
		
		if parts.size() == 2:
			var german_word = parts[0].strip_edges()
			var english_word = parts[1].strip_edges()
			vocabulary.append({"german": german_word, "english": english_word})


func create_exercise() -> Exercise:
	if vocabulary.is_empty():
		return Exercise.new("Keine Vokabeln verfügbar", "")
	
	var random_index = randi() % vocabulary.size()
	var word_pair = vocabulary[random_index]
	
	# 1 in 10 chance to ask for German word, 9 in 10 chance to ask for English word
	var ask_for_german = (randi() % 10) == 0
	
	var question: String
	var result: String
	
	if ask_for_german:
		question = "Wie lautet das deutsche Wort für: %s?" % word_pair["english"]
		result = word_pair["german"]
	else:
		question = "Wie lautet das englische Wort für: %s?" % word_pair["german"]
		result = word_pair["english"]
	
	return Exercise.new(question, result)
