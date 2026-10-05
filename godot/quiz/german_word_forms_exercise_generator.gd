class_name GermanWordFormsExerciseGenerator


const VERB_FORMS_PATH: String = "res://quiz/dictionaries/german_verb_forms.txt"
const PARTICIPLES_PATH: String = "res://quiz/dictionaries/german_participles.txt"
const NOUN_PLURALS_PATH: String = "res://quiz/dictionaries/german_noun_plurals.txt"
const WORD_FORMS_PATH: String = "res://quiz/dictionaries/german_word_forms.txt"


enum FormType {
	VERB_FORM,
	PARTICIPLE,
	NOUN_PLURAL,
	WORD_FORM
}

const EXERCISE_TYPES: Array[FormType] = [
	FormType.VERB_FORM,
	FormType.PARTICIPLE,
	FormType.NOUN_PLURAL,
	FormType.WORD_FORM
]


var verb_forms: Array = []
var participles: Array = []
var noun_plurals: Array = []
var word_forms: Array = []


func _init() -> void:
	_load_verb_forms()
	_load_participles()
	_load_noun_plurals()
	_load_word_forms()


func _load_verb_forms() -> void:
	var file = FileAccess.open(VERB_FORMS_PATH, FileAccess.READ)
		
	while file.get_position() < file.get_length():
		var line = file.get_line()
		var parts = line.split(",")
		
		if parts.size() == 3:
			verb_forms.append({
				"infinitive": parts[0].strip_edges(),
				"present_3sg": parts[1].strip_edges(),
				"preterite_3pl": parts[2].strip_edges()
			})


func _load_participles() -> void:
	var file = FileAccess.open(PARTICIPLES_PATH, FileAccess.READ)
		
	while file.get_position() < file.get_length():
		var line = file.get_line()
		var parts = line.split(",")
		
		if parts.size() == 2:
			participles.append({
				"infinitive": parts[0].strip_edges(),
				"participle": parts[1].strip_edges()
			})


func _load_noun_plurals() -> void:
	var file = FileAccess.open(NOUN_PLURALS_PATH, FileAccess.READ)
	
	while file.get_position() < file.get_length():
		var line = file.get_line()
		var parts = line.split(",")
		
		if parts.size() == 2:
			noun_plurals.append({
				"singular": parts[0].strip_edges(),
				"plural": parts[1].strip_edges()
			})


func _load_word_forms() -> void:
	var file = FileAccess.open(WORD_FORMS_PATH, FileAccess.READ)
		
	while file.get_position() < file.get_length():
		var line = file.get_line()
		var parts = line.split(",")
		
		if parts.size() == 2:
			word_forms.append({
				"question": parts[0].strip_edges(),
				"answer": parts[1].strip_edges()
			})


func create_exercise() -> Exercise:
	var form_type = EXERCISE_TYPES[randi() % EXERCISE_TYPES.size()]
	
	match form_type:
		FormType.VERB_FORM:
			return _create_verb_form_exercise()
		FormType.PARTICIPLE:
			return _create_participle_exercise()
		FormType.NOUN_PLURAL:
			return _create_noun_plural_exercise()
		_:
			return _create_word_form_exercise()


func _create_verb_form_exercise() -> Exercise:
	var entry = verb_forms[randi() % verb_forms.size()]
	
	if randi() % 2 == 0:
		var question = "Wie lautet die er/sie/es-Form (Präsens) von „%s“?" % entry["infinitive"]
		return Exercise.new(question, entry["present_3sg"])
	else:
		var question = "Wie lautet die Vergangenheitsform (Mehrzahl) von „%s“?" % entry["infinitive"]
		return Exercise.new(question, entry["preterite_3pl"])


func _create_participle_exercise() -> Exercise:
	var entry = participles[randi() % participles.size()]
	var question = "Wie heißt das Wort nach „ich habe“, wenn man „%s“ verwendet?" % entry["infinitive"]
	return Exercise.new(question, entry["participle"])


func _create_noun_plural_exercise() -> Exercise:
	var entry = noun_plurals[randi() % noun_plurals.size()]
	
	if randi() % 2 == 0:
		var question = "Wie lautet die Mehrzahl von „%s“?" % entry["singular"]
		return Exercise.new(question, entry["plural"])
	else:
		var question = "Wie lautet die Einzahl von „%s“?" % entry["plural"]
		return Exercise.new(question, entry["singular"])


func _create_word_form_exercise() -> Exercise:
	var entry = word_forms[randi() % word_forms.size()]
	return Exercise.new(entry["question"], entry["answer"])
