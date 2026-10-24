extends GutTest

const ITEM_CATALOG: ItemCatalog = preload("res://items/item_catalog.tres")


func test_weapon_id_resolves_to_weapon_resource():
	# arrange
	var weapon_id: String = "sword_iron"

	# act
	var weapon: WeaponResource = ITEM_CATALOG.get_weapon(weapon_id)

	# assert
	assert_eq(weapon.id, weapon_id, "Should return proper weapon")
	assert_eq(weapon.name, "Eisenschwert", "Should contain the display name")
	assert_eq(weapon.damage, 3, "Should contain the damage value")


func test_unknown_weapon_id_does_not_resolve():
	# arrange
	var unknown_id: String = "unknown"

	# act
	var weapon: WeaponResource = ITEM_CATALOG.get_weapon(unknown_id)

	# assert
	assert_null(weapon, "Should return null, when no weapon is found")


func test_armor_id_resolves_to_armor_resource():
	# arrange
	var armor_id: String = "helmet_stone"

	# act
	var armor: ArmorResource = ITEM_CATALOG.get_armor(armor_id)

	# assert
	assert_eq(armor.id, armor_id, "Should return proper armor")
	assert_eq(armor.name, "Steinhelm", "Should contain the display name")
	assert_eq(armor.armor, 2, "Should contain the armor value")


func test_unknown_armor_id_does_not_resolve():
	# arrange
	var unknown_id: String = "unknown"

	# act
	var armor: ArmorResource = ITEM_CATALOG.get_armor(unknown_id)

	# assert
	assert_null(armor, "Should return null, when no armor is found")
