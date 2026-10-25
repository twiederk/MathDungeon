extends GutTest

const ITEM_CATALOG: ItemCatalog = preload("res://items/item_catalog.tres")

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
	character.load_state("Steve", "000", 5, 0, 3, ITEM_CATALOG.get_weapon("sword_iron"), 2, ITEM_CATALOG.get_armor("helmet_iron"), ["Wolf"])

	# act
	SaveManager.save_character(character)

	# assert
	assert_false(SaveManager.character_exists(character.id), "A dead character should never be written")


func test_save_and_load_round_trip_persists_weapon_armor_and_base_stats():
	# arrange
	character.id = "1002"
	character.base_armor = 2
	character.inventory.equip_weapon(ITEM_CATALOG.get_weapon("sword_iron"))
	character.inventory.add_potion(_create_good("healing_potion"))
	SaveManager.save_character(character)

	# act
	SaveManager.load_and_activate_character(character.id)

	# assert
	var loaded := CharacterManager.current
	assert_eq("sword_iron", loaded.inventory.get_weapon_id())
	assert_eq(3, loaded.inventory.get_weapon_damage())
	assert_eq(2, loaded.base_armor)
	assert_eq(0, loaded.inventory.get_potion_count(), "Potions are session-only and must not be persisted")


func test_legacy_save_without_base_stats_falls_back_to_the_old_totals():
	# arrange
	character.id = "1003"
	var legacy = {
		"id": character.id,
		"display_name": "Steve",
		"portrait_id": "000",
		"max_hit_points": 5,
		"hit_points": 5,
		"weapon_damage": 4,
		"armor": 2,
		"companions": [],
	}
	DirAccess.make_dir_recursive_absolute("user://characters/")
	var save_file := FileAccess.open("user://characters/%s.save" % character.id, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(legacy))
	save_file.close()

	# act
	SaveManager.load_and_activate_character(character.id)

	# assert
	var loaded := CharacterManager.current
	assert_eq(4, loaded.base_damage, "The old weapon_damage total becomes the new base damage")
	assert_eq(2, loaded.base_armor, "The old armor total becomes the new base armor")


func _create_good(id: String) -> GoodResource:
	var resource := GoodResource.new()
	resource.id = id
	resource.name = id
	return resource
