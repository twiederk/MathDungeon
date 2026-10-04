class_name Character


const PORTRAIT_CATALOG: PortraitCatalog = preload("res://characters/portrait_catalog.tres")
const WOLF_DAMAGE: int = 1

signal weapon_damage_changed
signal armor_changed
signal has_lighter_changed
signal hit_points_changed

var id: String
var display_name: String
var portrait_id: String
var portrait: Portrait:
	get:
		return PORTRAIT_CATALOG.get_portrait(portrait_id)
var max_hit_points: int = 5
var companion_types: Array[String] = []

var hit_points: int = 5:
	get:
		return _hit_points
	set(value):
		_hit_points = clampi(value, 0, max_hit_points)
		hit_points_changed.emit()
		if _hit_points > 0:
			SaveManager.save_character(self)

var weapon_damage: int = 1:
	get:
		return _weapon_damage
	set(value):
		_weapon_damage = value
		weapon_damage_changed.emit()
		SaveManager.save_character(self)

var armor: int = 0:
	get:
		return _armor
	set(value):
		_armor = value
		armor_changed.emit()
		SaveManager.save_character(self)

var _weapon_damage: int = 1
var _armor: int = 0
var _hit_points: int = 5

var _has_lighter: bool = false:
	set(value):
		_has_lighter = value
		has_lighter_changed.emit()
		SaveManager.save_character(self)


func get_damage() -> int:
	return weapon_damage


func get_total_damage() -> int:
	var total = get_damage()
	for companion_type in companion_types:
		if companion_type == "Wolf":
			total += WOLF_DAMAGE
	return total


func get_armor() -> int:
	return armor


func has_item(item_id: String) -> bool:
	return item_id == "lighter" and _has_lighter


func set_has_lighter(value: bool) -> void:
	_has_lighter = value


func hurt(damage: int) -> int:
	hit_points -= max(1, damage - get_armor())
	return hit_points


func needs_healing() -> bool:
	return hit_points < max_hit_points


func add_companion_type(companion_type: String) -> void:
	companion_types.append(companion_type)
	weapon_damage_changed.emit()
	SaveManager.save_character(self)


func load_state(a_display_name: String, a_portrait_id: String, a_max_hit_points: int, a_hit_points: int, a_damage: int, a_armor: int, a_companion_types: Array[String]) -> void:
	display_name = a_display_name
	portrait_id = a_portrait_id
	max_hit_points = a_max_hit_points
	_hit_points = clampi(a_hit_points, 0, a_max_hit_points)
	_weapon_damage = a_damage
	_armor = a_armor
	companion_types = a_companion_types
