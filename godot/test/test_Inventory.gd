extends GutTest


var inventory: Inventory = null


func before_each():
	inventory = Inventory.new()


func test_equip_weapon_with_higher_damage_replaces_it():
	# arrange
	watch_signals(inventory)

	# act
	var result = inventory.equip_weapon("sword_iron", 3)

	# assert
	assert_true(result)
	assert_eq("sword_iron", inventory.weapon_item_id)
	assert_eq(3, inventory.weapon_damage)
	assert_signal_emitted(inventory, "changed")


func test_equip_weapon_with_lower_or_equal_damage_is_rejected():
	# arrange
	inventory.equip_weapon("sword_iron", 3)

	# act
	var result = inventory.equip_weapon("sword_stone", 2)

	# assert
	assert_false(result)
	assert_eq("sword_iron", inventory.weapon_item_id)
	assert_eq(3, inventory.weapon_damage)


func test_equip_armor_with_higher_value_replaces_it():
	# arrange
	watch_signals(inventory)

	# act
	var result = inventory.equip_armor("helmet_iron", 2)

	# assert
	assert_true(result)
	assert_eq("helmet_iron", inventory.armor_item_id)
	assert_eq(2, inventory.armor_value)
	assert_signal_emitted(inventory, "changed")


func test_equip_armor_with_lower_or_equal_value_is_rejected():
	# arrange
	inventory.equip_armor("helmet_iron", 2)

	# act
	var result = inventory.equip_armor("helmet_wood", 1)

	# assert
	assert_false(result)
	assert_eq("helmet_iron", inventory.armor_item_id)
	assert_eq(2, inventory.armor_value)


func test_add_potion_is_rejected_once_at_max():
	# arrange
	for i in Inventory.MAX_POTIONS:
		inventory.add_potion()

	# act
	var result = inventory.add_potion()

	# assert
	assert_false(result)
	assert_eq(Inventory.MAX_POTIONS, inventory.potion_count)


func test_add_potion_increments_count_and_emits_changed():
	# arrange
	watch_signals(inventory)

	# act
	var result = inventory.add_potion()

	# assert
	assert_true(result)
	assert_eq(1, inventory.potion_count)
	assert_signal_emitted(inventory, "changed")


func test_use_potion_is_rejected_when_empty():
	# act
	var result = inventory.use_potion()

	# assert
	assert_false(result)
	assert_eq(0, inventory.potion_count)


func test_use_potion_decrements_count_and_emits_changed():
	# arrange
	inventory.add_potion()
	watch_signals(inventory)

	# act
	var result = inventory.use_potion()

	# assert
	assert_true(result)
	assert_eq(0, inventory.potion_count)
	assert_signal_emitted(inventory, "changed")
