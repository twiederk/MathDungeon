extends GutTest

var character_create_dialog: CharacterCreateDialog = null


func before_each():
	character_create_dialog = CharacterCreateDialog.new()
	character_create_dialog.selected_portrait_id = "000"


func after_each():
	character_create_dialog.free()


func test_create_character_sets_default_values():
	# arrange
	var character_name = "TestCharacter"
	var expected_display_name = "TestCharacter"
	var expected_portrait_id = "000"
	var expected_max_hit_points = 5
	var expected_hit_points = 5
	var expected_weapon_damage = 1
	var expected_armor = 0
	var expected_companions_size = 0

	# act
	var character = character_create_dialog._create_character(character_name)

	# assert
	assert_true(character is Character, "Should return a Character object")
	assert_eq(expected_display_name, character.display_name, "Should set the display name correctly")
	assert_eq(expected_portrait_id, character.portrait_id, "Should set the portrait id from selected_portrait_id")
	assert_eq(expected_max_hit_points, character.max_hit_points, "Should set max_hit_points to 5")
	assert_eq(expected_hit_points, character.hit_points, "Should set hit_points to 5")
	assert_eq(expected_weapon_damage, character.weapon_damage, "Should set weapon_damage to 1")
	assert_eq(expected_armor, character.armor, "Should set armor to 0")
	assert_eq(expected_companions_size, character.companion_types.size(), "Should initialize companion_types as empty array")
	assert_ne("", character.id, "Character ID should not be empty")
