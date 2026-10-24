class_name ItemCatalog
extends Resource

@export var weapons: Array[WeaponResource] = []
@export var armors: Array[ArmorResource] = []


func get_weapon(weapon_id: String) -> WeaponResource:
	for weapon in weapons:
		if weapon.id == weapon_id:
			return weapon
	return null


func get_armor(armor_id: String) -> ArmorResource:
	for armor in armors:
		if armor.id == armor_id:
			return armor
	return null
