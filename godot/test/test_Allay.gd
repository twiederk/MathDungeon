extends GutTest

const ITEM_CATALOG: ItemCatalog = preload("res://items/item_catalog.tres")

var allay: Allay = null


func before_each():
	allay = Allay.new()
	CharacterManager.current = Character.new()


func after_each():
	allay.free()
	allay = null


func test_execute_raises_base_armor_without_touching_the_equipped_armor():
	# arrange
	var helmet := ITEM_CATALOG.get_armor("helmet_iron")
	CharacterManager.current.inventory.equip_armor(helmet)

	# act
	CharacterManager.current.base_armor += 1

	# assert
	assert_eq(1, CharacterManager.current.base_armor)
	assert_same(helmet, CharacterManager.current.inventory.armor_resource, "The Allay bonus must not clear the equipped helmet")
	assert_eq(4, CharacterManager.current.get_armor(), "Base armor and the equipped helmet stack")
