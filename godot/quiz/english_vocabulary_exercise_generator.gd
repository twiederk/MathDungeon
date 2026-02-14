class_name EnglishVocabularyExerciseGenerator


const dictionary_file_path: String = "res://quiz/dictionary.txt"


var vocabulary: Array = []


func _init() -> void:
	_load_dictionary()


func _load_dictionary() -> void:
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
	
	var question = "Wie lautet das englische Wort für: %s?" % word_pair["german"]
	var result = word_pair["english"]
	
	return Exercise.new(question, result)
