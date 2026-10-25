extends GutTest


var inventory: Inventory = null


func before_each():
	inventory = Inventory.new()


func test_equip_weapon_with_higher_damage_replaces_it():
	# arrange
	watch_signals(inventory)

	# act
	var result = inventory.equip_weapon(_weapon("sword_iron", 3))

	# assert
	assert_true(result)
	assert_eq("sword_iron", inventory.get_weapon_id())
	assert_eq(3, inventory.get_weapon_damage())
	assert_signal_emitted(inventory, "changed")


func test_equip_weapon_with_lower_or_equal_damage_is_rejected():
	# arrange
	inventory.equip_weapon(_weapon("sword_iron", 3))

	# act
	var result = inventory.equip_weapon(_weapon("sword_stone", 2))

	# assert
	assert_false(result)
	assert_eq("sword_iron", inventory.get_weapon_id())
	assert_eq(3, inventory.get_weapon_damage())


func test_empty_weapon_slot_contributes_no_damage():
	# act
	var result = inventory.get_weapon_damage()

	# assert
	assert_eq(0, result)
	assert_eq("", inventory.get_weapon_id())


func test_equip_armor_with_higher_value_replaces_it():
	# arrange
	watch_signals(inventory)

	# act
	var result = inventory.equip_armor(_armor("helmet_iron", 2))

	# assert
	assert_true(result)
	assert_eq("helmet_iron", inventory.get_armor_id())
	assert_eq(2, inventory.get_armor_value())
	assert_signal_emitted(inventory, "changed")


func test_equip_armor_with_lower_or_equal_value_is_rejected():
	# arrange
	inventory.equip_armor(_armor("helmet_iron", 2))

	# act
	var result = inventory.equip_armor(_armor("helmet_wood", 1))

	# assert
	assert_false(result)
	assert_eq("helmet_iron", inventory.get_armor_id())
	assert_eq(2, inventory.get_armor_value())


func test_empty_armor_slot_contributes_no_armor():
	# act
	var result = inventory.get_armor_value()

	# assert
	assert_eq(0, result)
	assert_eq("", inventory.get_armor_id())


func test_add_potion_is_rejected_once_at_max():
	# arrange
	for i in Inventory.MAX_POTIONS:
		inventory.add_potion(_create_good("healing_potion"))

	# act
	var result = inventory.add_potion(_create_good("healing_potion"))

	# assert
	assert_false(result)
	assert_eq(Inventory.MAX_POTIONS, inventory.get_potion_count())


func test_add_potion_increments_count_and_emits_changed():
	# arrange
	watch_signals(inventory)

	# act
	var result = inventory.add_potion(_create_good("healing_potion"))

	# assert
	assert_true(result)
	assert_eq(1, inventory.get_potion_count())
	assert_signal_emitted(inventory, "changed")


func test_use_potion_is_rejected_when_empty():
	# act
	var result = inventory.use_potion()

	# assert
	assert_false(result)
	assert_eq(0, inventory.get_potion_count())


func test_use_potion_decrements_count_and_emits_changed():
	# arrange
	inventory.add_potion(_create_good("healing_potion"))
	watch_signals(inventory)

	# act
	var result = inventory.use_potion()

	# assert
	assert_true(result)
	assert_eq(0, inventory.get_potion_count())
	assert_signal_emitted(inventory, "changed")


func test_equip_good_appends_to_goods_and_emits_changed():
	# arrange
	watch_signals(inventory)

	# act
	inventory.equip_good(_create_good("eye_of_ender"))

	# assert
	assert_eq(1, inventory.goods.size())
	assert_signal_emitted(inventory, "changed")


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


func _create_good(id: String) -> GoodResource:
	var resource := GoodResource.new()
	resource.id = id
	resource.name = id
	return resource
