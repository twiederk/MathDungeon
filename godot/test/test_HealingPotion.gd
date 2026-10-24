extends GutTest

var healing_potion: HealingPotion = null


func before_each():
	healing_potion = HealingPotion.new()
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
	assert_eq(1, CharacterManager.current.inventory.potion_count)
	assert_eq(4, CharacterManager.current.hit_points)


func test_execute_is_rejected_once_potion_slot_is_full():
	# arrange
	for i in Inventory.MAX_POTIONS:
		CharacterManager.current.inventory.add_potion()

	# act
	healing_potion.execute()

	# assert
	assert_eq(Inventory.MAX_POTIONS, CharacterManager.current.inventory.potion_count)
