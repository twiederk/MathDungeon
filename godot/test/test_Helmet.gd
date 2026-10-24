extends GutTest

var helmet: Helmet = null


func before_each():
	helmet = Helmet.new()
	CharacterManager.current = Character.new()


func after_each():
	helmet.free()
	helmet = null


func test_execute_equips_stronger_armor():
	# arrange
	helmet.armor = 2
	helmet.item_id = "helmet_stone"

	# act
	helmet.execute()

	# assert
	assert_eq("helmet_stone", CharacterManager.current.inventory.armor_item_id)
	assert_eq(2, CharacterManager.current.armor)


func test_execute_does_not_downgrade_the_armor():
	# arrange
	CharacterManager.current.inventory.equip_armor("helmet_stone", 2)
	helmet.armor = 1
	helmet.item_id = "helmet_wood"

	# act
	helmet.execute()

	# assert
	assert_eq("helmet_stone", CharacterManager.current.inventory.armor_item_id)
	assert_eq(2, CharacterManager.current.armor)
