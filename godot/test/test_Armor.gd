extends GutTest

var helmet: Armor = null


func before_each():
	helmet = Armor.new()
	CharacterManager.current = Character.new()


func after_each():
	helmet.free()
	helmet = null


func test_get_item_resource_returns_assigned_resource():
	# arrange
	var resource := _armor("helmet_stone", 2)
	helmet.armor_resource = resource

	# act
	var actual_resource: ArmorResource = helmet.get_item_resource()

	# assert
	assert_eq(actual_resource, resource)


func test_get_level_delegates_to_armor_resource():
	# arrange
	helmet.armor_resource = _armor("helmet_stone", 2)

	# act
	var actual_level = helmet.get_level()

	# assert
	assert_eq(actual_level, 4)


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
