extends GutTest

var character: Character = null


func before_each():
	character = Character.new()
	

func after_each():
	var path := "user://characters/%s.save" % character.id
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	character = null


func test_save_character_creates_file():
	# arrange
	var character_id = "1001"
	character.id = character_id
	
	# act
	SaveManager.save_character(character)

	# assert
	assert_true(SaveManager.character_exists(character.id))


func test_save_character_is_skipped_while_dead():
	# arrange
	character.load_state("Steve", "000", 5, 0, 3, 2, ["/root/Main/Companions/Wolf1"], ["Wolf"])

	# act
	SaveManager.save_character(character)

	# assert
	assert_false(SaveManager.character_exists(character.id), "A dead character should never be written")
