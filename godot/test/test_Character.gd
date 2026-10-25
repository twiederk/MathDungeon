extends GutTest

var character: Character = null


func before_each():
	character = Character.new()
	character.load_state("Steve", "steve", 5, 5, 1, null, 0, null, [])


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
	character.base_armor = 3

	# act
	var result = character.hurt(5)

	# assert
	assert_eq(3, result)


func test_get_armor_adds_base_armor_and_equipped_armor():
	# arrange
	character.base_armor = 1
	character.inventory.equip_armor(_armor("helmet_stone", 2))

	# act
	var result = character.get_armor()

	# assert
	assert_eq(3, result, "Armor is the sum of base armor and the equipped armor resource")


func test_get_damage_adds_base_damage_and_equipped_weapon():
	# arrange
	character.inventory.equip_weapon(_weapon("sword_iron", 3))

	# act
	var result = character.get_damage()

	# assert
	assert_eq(4, result, "Damage is the sum of base damage and the equipped weapon resource")


func test_get_damage_without_companions():
	# act
	var result = character.get_damage()

	# assert
	assert_eq(1, result, "Damage equals the base damage when nothing is equipped and no companion is owned")


func test_get_damage_adds_one_per_wolf():
	# arrange
	character.add_companion("Wolf")
	character.add_companion("Wolf")

	# act
	var result = character.get_damage()

	# assert
	assert_eq(3, result, "Each wolf adds one damage on top of the base damage")


func test_get_damage_ignores_unknown_companion_types():
	# arrange
	character.add_companion("Allay")

	# act
	var result = character.get_damage()

	# assert
	assert_eq(1, result, "Unknown companion types contribute no damage")


func test_get_eyes_of_ender_count_counts_matching_goods():
	# act
	character.equip_good(_good("eye_of_ender"))

	# assert
	assert_eq(1, character.get_eyes_of_ender_count())


func test_equip_good_emits_eyes_of_ender_changed():
	# arrange
	watch_signals(character)

	# act
	character.equip_good(_good("eye_of_ender"))

	# assert
	assert_signal_emitted(character, "eyes_of_ender_changed")


func test_has_lighter_false_without_pickup():
	# act
	var result = character.has_lighter()

	# assert
	assert_false(result)


func test_equip_good_grants_lighter_and_emits_has_lighter_changed():
	# arrange
	watch_signals(character)

	# act
	character.equip_good(_good("lighter"))

	# assert
	assert_true(character.has_lighter())
	assert_signal_emitted(character, "has_lighter_changed")


func _weapon(id: String, damage: int) -> WeaponResource:
	var resource := WeaponResource.new()
	resource.id = id
	resource.name = id
	resource.damage = damage
	return resource


func _armor(id: String, armor: int) -> ArmorResource:
	var resource := ArmorResource.new()
	resource.id = id
	resource.name = id
	resource.armor = armor
	return resource


func _good(id: String) -> GoodResource:
	var resource := GoodResource.new()
	resource.id = id
	resource.name = id
	return resource
