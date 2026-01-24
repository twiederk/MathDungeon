extends GutTest

var lighter: Lighter = null


func before_each():
	lighter = Lighter.new()


func after_each():
	lighter.free()
	lighter = null


func test_create_exercise():
	# arrange
	PlayerStats.has_lighter = false
	
	# act
	lighter.execute()
	
	# assert
	assert_true(PlayerStats.has_lighter, "Player should have lighter")
