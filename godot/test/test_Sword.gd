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
	sword.weapon_resource = _weapon("sword_iron", 3)

	# act
	sword.execute()

	# assert
	assert_eq("sword_iron", CharacterManager.current.inventory.get_weapon_id())
	assert_eq(3, CharacterManager.current.inventory.get_weapon_damage())


func test_execute_does_not_downgrade_the_weapon():
	# arrange
	CharacterManager.current.inventory.equip_weapon(_weapon("sword_iron", 3))
	sword.weapon_resource = _weapon("sword_stone", 2)

	# act
	sword.execute()

	# assert
	assert_eq("sword_iron", CharacterManager.current.inventory.get_weapon_id())
	assert_eq(3, CharacterManager.current.inventory.get_weapon_damage())


func _weapon(id: String, damage: int) -> WeaponResource:
	var resource := WeaponResource.new()
	resource.id = id
	resource.name = id
	resource.damage = damage
	return resource
