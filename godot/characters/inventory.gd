class_name Inventory


enum SlotType { WEAPON, ARMOR, CONSUMABLE_POTION }

const MAX_POTIONS: int = 5

signal changed

var weapon_resource: WeaponResource = null
var armor_resource: ArmorResource = null
var potion_count: int = 0


func equip_weapon(resource: WeaponResource) -> bool:
	if resource == null or resource.damage <= get_weapon_damage():
		return false
	weapon_resource = resource
	changed.emit()
	return true


func equip_armor(resource: ArmorResource) -> bool:
	if resource == null or resource.armor <= get_armor_value():
		return false
	armor_resource = resource
	changed.emit()
	return true


func get_weapon_damage() -> int:
	if weapon_resource == null:
		return 0
	return weapon_resource.damage


func get_armor_value() -> int:
	if armor_resource == null:
		return 0
	return armor_resource.armor


func get_weapon_id() -> String:
	if weapon_resource == null:
		return ""
	return weapon_resource.id


func get_armor_id() -> String:
	if armor_resource == null:
		return ""
	return armor_resource.id


func get_weapon_name() -> String:
	if weapon_resource == null:
		return ""
	return weapon_resource.name


func get_armor_name() -> String:
	if armor_resource == null:
		return ""
	return armor_resource.name


func add_potion() -> bool:
	if potion_count >= MAX_POTIONS:
		return false
	potion_count += 1
	changed.emit()
	return true


func use_potion() -> bool:
	if potion_count <= 0:
		return false
	potion_count -= 1
	changed.emit()
	return true
