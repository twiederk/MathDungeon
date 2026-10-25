extends GutTest

var lighter: Lighter = null


func before_each():
	lighter = Lighter.new()
	lighter.good_resource = _create_good("lighter")


func after_each():
	lighter.free()
	lighter = null
	CharacterManager.current.inventory.goods.clear()


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
