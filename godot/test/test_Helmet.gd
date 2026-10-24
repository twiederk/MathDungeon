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
	helmet.armor_resource = _armor("helmet_stone", 2)

	# act
	helmet.execute()

	# assert
	assert_eq("helmet_stone", CharacterManager.current.inventory.get_armor_id())
	assert_eq(2, CharacterManager.current.get_armor())


func test_execute_does_not_downgrade_the_armor():
	# arrange
	CharacterManager.current.inventory.equip_armor(_armor("helmet_stone", 2))
	helmet.armor_resource = _armor("helmet_wood", 1)

	# act
	helmet.execute()

	# assert
	assert_eq("helmet_stone", CharacterManager.current.inventory.get_armor_id())
	assert_eq(2, CharacterManager.current.get_armor())


func _armor(id: String, armor: int) -> ArmorResource:
	var resource := ArmorResource.new()
	resource.id = id
	resource.name = id
	resource.armor = armor
	return resource
