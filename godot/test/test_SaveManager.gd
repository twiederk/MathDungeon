extends GutTest

var character: Character = null


func before_each():
	character = Character.new()
	# load_state() avoids the property setters' save-on-write side effect during setup
	character.load_state("Steve", "steve", 8, 5, 3, 2, ["/root/Main/Companions/Wolf1"])


func after_each():
	var path := "user://characters/%s.save" % character.id
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	character = null


func test_save_character_creates_file():
	# act
	SaveManager.save_character(character)

	# assert
	assert_true(SaveManager.character_exists(character.id))


func test_save_character_is_skipped_while_dead():
	# arrange
	character.hit_points = 0

	# act
	SaveManager.save_character(character)

	# assert
	assert_false(SaveManager.character_exists(character.id), "A dead character should never be written")
