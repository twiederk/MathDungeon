class_name ItemCatalog
extends Resource

@export var weapons: Array[WeaponResource] = []
@export var armors: Array[ArmorResource] = []
@export var goods: Array[GoodResource] = []


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


func get_good(good_id: String) -> GoodResource:
	for good in goods:
		if good.id == good_id:
			return good
	return null
