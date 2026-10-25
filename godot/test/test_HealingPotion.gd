extends GutTest

var healing_potion: HealingPotion = null


func before_each():
	healing_potion = HealingPotion.new()
	healing_potion.good_resource = _create_good("healing_potion")
	CharacterManager.current = Character.new()


func after_each():
	healing_potion.free()
	healing_potion = null


func test_execute_stores_a_potion_instead_of_healing():
	# arrange
	CharacterManager.current.hit_points = 4

	# act
	healing_potion.execute()

	# assert
	assert_eq(1, CharacterManager.current.inventory.get_potion_count())
	assert_eq(4, CharacterManager.current.hit_points)


func test_execute_is_rejected_once_potion_slot_is_full():
	# arrange
	for i in Inventory.MAX_POTIONS:
		CharacterManager.current.inventory.add_potion(_create_good("healing_potion"))

	# act
	healing_potion.execute()

	# assert
	assert_eq(Inventory.MAX_POTIONS, CharacterManager.current.inventory.get_potion_count())


func _create_good(id: String) -> GoodResource:
	var resource := GoodResource.new()
	resource.id = id
	resource.name = id
	return resource
