extends GutTest

const HEALING_POTION: GoodResource = preload("res://procedural/items/healing_potion_good.tres")


func test_weapon_level_uses_damage_formula():
	# arrange
	var weapon := WeaponResource.new()
	weapon.damage = 3

	# act
	var actual_level = weapon.get_level()

	# assert
	assert_eq(actual_level, 4)


func test_armor_level_uses_armor_formula():
	# arrange
	var armor := ArmorResource.new()
	armor.armor = 2

	# act
	var actual_level = armor.get_level()

	# assert
	assert_eq(actual_level, 4)


func test_good_level_uses_configured_level():
	# arrange
	var good := GoodResource.new()
	good.level = 5

	# act
	var actual_level = good.get_level()

	# assert
	assert_eq(actual_level, 5)


func test_good_level_preserves_all_levels_sentinel():
	# arrange
	var good: GoodResource = HEALING_POTION

	# act
	var actual_level = good.get_level()

	# assert
	assert_eq(actual_level, GoodResource.LEVEL_ALL_DUNGEON_LEVELS)
