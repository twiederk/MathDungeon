extends GutTest

var sword: Sword = null


func before_each():
	sword = Sword.new()
	CharacterManager.current = Character.new()


func after_each():
	sword.free()
	sword = null


func test_execute_equips_a_stronger_sword():
	# arrange
	sword.damage = 3
	sword.item_id = "sword_iron"

	# act
	sword.execute()

	# assert
	assert_eq("sword_iron", CharacterManager.current.inventory.weapon_item_id)
	assert_eq(3, CharacterManager.current.weapon_damage)


func test_execute_does_not_downgrade_the_weapon():
	# arrange
	CharacterManager.current.inventory.equip_weapon("sword_iron", 3)
	sword.damage = 2
	sword.item_id = "sword_stone"

	# act
	sword.execute()

	# assert
	assert_eq("sword_iron", CharacterManager.current.inventory.weapon_item_id)
	assert_eq(3, CharacterManager.current.weapon_damage)
