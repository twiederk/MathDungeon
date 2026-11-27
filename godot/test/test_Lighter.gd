extends GutTest

var lighter: Lighter = null


func before_each():
	lighter = Lighter.new()
	lighter.good_resource = _create_good("lighter")


func after_each():
	lighter.free()
	lighter = null
	CharacterManager.current.inventory.goods.clear()


func test_get_item_resource_returns_assigned_resource():
	# arrange
	var resource := _create_good("lighter")
	lighter.good_resource = resource

	# act
	var actual_resource: GoodResource = lighter.get_item_resource()

	# assert
	assert_eq(actual_resource, resource)


func test_get_level_delegates_to_good_resource():
	# arrange
	lighter.good_resource.level = 3

	# act
	var actual_level = lighter.get_level()

	# assert
	assert_eq(actual_level, 3)


func test_execute():
	# act
	lighter.execute()
	
	# assert
	assert_true(CharacterManager.current.has_lighter(), "Player should have lighter")


func _create_good(id: String) -> GoodResource:
	var resource := GoodResource.new()
	resource.id = id
	resource.name = id
	return resource
