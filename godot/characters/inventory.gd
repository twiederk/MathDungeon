class_name Inventory


enum SlotType { WEAPON, ARMOR, CONSUMABLE_POTION }

const MAX_POTIONS: int = 5

signal changed

var weapon_item_id: String = ""
var weapon_damage: int = 0
var armor_item_id: String = ""
var armor_value: int = 0
var potion_count: int = 0


func equip_weapon(item_id: String, damage: int) -> bool:
	if damage <= weapon_damage:
		return false
	weapon_item_id = item_id
	weapon_damage = damage
	changed.emit()
	return true


func equip_armor(item_id: String, armor: int) -> bool:
	if armor <= armor_value:
		return false
	armor_item_id = item_id
	armor_value = armor
	changed.emit()
	return true


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
