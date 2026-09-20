extends GutTest

var character: Character = null


func before_each():
	character = Character.new()
	character.load_state("Steve", "steve", 5, 5, 1, 0, [])


func after_each():
	character = null


func test_needs_healing_true():
	# arrange
	character.hit_points = 4

	# act
	var result = character.needs_healing()

	# assert
	assert_true(result, "Player need healing if hit points are lower than max hit points")


func test_needs_healing_false():
	# arrange
	character.hit_points = 5

	# act
	var result = character.needs_healing()

	# assert
	assert_false(result, "Player doesn't need healing if hit points are equal to max hit points")


func test_hurt_reduces_hit_points_by_at_least_one():
	# act
	var result = character.hurt(1)

	# assert
	assert_eq(4, result)


func test_hurt_is_reduced_by_armor():
	# arrange
	character.armor = 3

	# act
	var result = character.hurt(5)

	# assert
	assert_eq(3, result)
