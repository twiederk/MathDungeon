class_name Character


const PORTRAIT_CATALOG: PortraitCatalog = preload("res://characters/portrait_catalog.tres")
const HIT_EFFECT_SCENE: PackedScene = preload("res://enemies/hit_effect.tscn")
const WOLF_DAMAGE: int = 1
const EYE_OF_ENDER_ID: String = "eye_of_ender"

signal damage_changed
signal armor_changed
signal hit_points_changed
signal eyes_of_ender_changed
signal has_lighter_changed

var id: String
var display_name: String
var portrait_id: String
var portrait: Portrait:
	get:
		return PORTRAIT_CATALOG.get_portrait(portrait_id)
var max_hit_points: int = 5
var companions: Array[String] = []
var inventory: Inventory = Inventory.new()

var has_lighter: bool = false:
	set(value):
		has_lighter = value
		has_lighter_changed.emit()

var hit_points: int = 5:
	get:
		return _hit_points
	set(value):
		_hit_points = clampi(value, 0, max_hit_points)
		hit_points_changed.emit()
		if _hit_points > 0:
			SaveManager.save_character(self)
var _hit_points: int = 5

var base_damage: int = 0:
	get:
		return _base_damage
	set(value):
		_base_damage = value
		damage_changed.emit()
		SaveManager.save_character(self)
var _base_damage: int = 0

var base_armor: int = 0:
	get:
		return _base_armor
	set(value):
		_base_armor = value
		armor_changed.emit()
		SaveManager.save_character(self)
var _base_armor: int = 0



func _init() -> void:
	inventory.changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	damage_changed.emit()
	armor_changed.emit()
	SaveManager.save_character(self)


func get_damage() -> int:
	return _base_damage + inventory.get_weapon_damage() + get_wolf_count() * WOLF_DAMAGE


func get_wolf_count() -> int:
	return get_companion_count("Wolf")


func get_allay_count() -> int:
	return get_companion_count("Allay")


func get_companion_count(companion_type: String) -> int:
	var count = 0
	for c_type in companions:
		if c_type == companion_type:
			count += 1
	return count


func get_armor() -> int:
	return _base_armor + inventory.get_armor_value()


func get_eyes_of_ender_count() -> int:
	var count := 0
	for good in inventory.goods:
		if good.id == EYE_OF_ENDER_ID:
			count += 1
	return count


func equip_good(resource: GoodResource) -> void:
	inventory.equip_good(resource)
	if resource.id == EYE_OF_ENDER_ID:
		eyes_of_ender_changed.emit()


func hurt(damage: int) -> int:
	Sound.play(Sound.hurt_player)
	_spawn_hit_effect()
	hit_points -= max(1, damage - get_armor())
	return hit_points


func _spawn_hit_effect() -> void:
	var player := _find_player()
	if player == null:
		return
	var effect := HIT_EFFECT_SCENE.instantiate()
	effect.global_position = player.global_position
	player.get_tree().current_scene.add_child(effect)


func _find_player() -> Node2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.find_child("Player", true, false) as Node2D


func needs_healing() -> bool:
	return hit_points < max_hit_points


func use_healing_potion() -> bool:
	if not needs_healing():
		return false
	if not inventory.use_potion():
		return false
	hit_points = max_hit_points
	Sound.play(Sound.pickup_potion)
	return true


func add_companion(companion_type: String) -> void:
	companions.append(companion_type)
	damage_changed.emit()
	SaveManager.save_character(self)


func load_state(a_display_name: String, a_portrait_id: String, a_max_hit_points: int, a_hit_points: int, a_base_damage: int, a_weapon: WeaponResource, a_base_armor: int, a_armor: ArmorResource, a_companions: Array[String]) -> void:
	display_name = a_display_name
	portrait_id = a_portrait_id
	max_hit_points = a_max_hit_points
	_hit_points = clampi(a_hit_points, 0, a_max_hit_points)
	_base_damage = a_base_damage
	_base_armor = a_base_armor
	inventory.equip_weapon(a_weapon)
	inventory.equip_armor(a_armor)
	companions = a_companions
