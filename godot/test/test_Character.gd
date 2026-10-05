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


func test_get_total_damage_without_companions():
	# act
	var result = character.get_total_damage()

	# assert
	assert_eq(1, result, "Total damage equals the weapon damage when no companion is owned")


func test_get_total_damage_adds_one_per_wolf():
	# arrange
	character.add_companion("Wolf")
	character.add_companion("Wolf")

	# act
	var result = character.get_total_damage()

	# assert
	assert_eq(3, result, "Each wolf adds one damage on top of the weapon damage")


func test_get_total_damage_ignores_unknown_companion_types():
	# arrange
	character.add_companion("Allay")

	# act
	var result = character.get_total_damage()

	# assert
	assert_eq(1, result, "Unknown companion types contribute no damage")
