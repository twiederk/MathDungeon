extends GutTest

var healing_potion: HealingPotion = null


func before_each():
	healing_potion = HealingPotion.new()


func after_each():
	healing_potion.free()
	healing_potion = null


func test_execute_heal_player():
	# arrange
	PlayerStats.hit_points = 4
	
	# act
	healing_potion.execute()
	
	# assert
	assert_eq(5, PlayerStats.hit_points)
