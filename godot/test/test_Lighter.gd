extends GutTest

var lighter: Lighter = null


func before_each():
	lighter = Lighter.new()


func after_each():
	lighter.free()
	lighter = null


func test_execute():
	# arrange
	CharacterManager.current.set_has_lighter(false)
	
	# act
	lighter.execute()
	
	# assert
	assert_true(CharacterManager.current.has_item("lighter"), "Player should have lighter")
