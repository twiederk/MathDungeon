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
	character.load_state("Steve", "000", 5, 0, 3, "sword_iron", 2, "helmet_iron", ["Wolf"])

	# act
	SaveManager.save_character(character)

	# assert
	assert_false(SaveManager.character_exists(character.id), "A dead character should never be written")


func test_save_and_load_round_trip_persists_weapon_and_armor_only():
	# arrange
	character.id = "1002"
	character.inventory.equip_weapon("sword_iron", 3)
	character.inventory.add_potion()
	SaveManager.save_character(character)

	# act
	SaveManager.load_and_activate_character(character.id)

	# assert
	var loaded := CharacterManager.current
	assert_eq("sword_iron", loaded.inventory.weapon_item_id)
	assert_eq(3, loaded.weapon_damage)
	assert_eq(0, loaded.inventory.potion_count)
