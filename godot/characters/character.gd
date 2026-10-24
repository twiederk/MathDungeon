class_name Character


const PORTRAIT_CATALOG: PortraitCatalog = preload("res://characters/portrait_catalog.tres")
const HIT_EFFECT_SCENE: PackedScene = preload("res://enemies/hit_effect.tscn")
const WOLF_DAMAGE: int = 1

signal weapon_damage_changed
signal armor_changed
signal hit_points_changed

var id: String
var display_name: String
var portrait_id: String
var portrait: Portrait:
	get:
		return PORTRAIT_CATALOG.get_portrait(portrait_id)
var max_hit_points: int = 5
var companions: Array[String] = []
var inventory: Inventory = Inventory.new()

var hit_points: int = 5:
	get:
		return _hit_points
	set(value):
		_hit_points = clampi(value, 0, max_hit_points)
		hit_points_changed.emit()
		if _hit_points > 0:
			SaveManager.save_character(self)

var weapon_damage: int:
	get:
		return inventory.weapon_damage
	set(value):
		inventory.equip_weapon("", value)

var armor: int:
	get:
		return inventory.armor_value
	set(value):
		inventory.equip_armor("", value)

var _hit_points: int = 5


func _init() -> void:
	inventory.weapon_damage = 1
	inventory.changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	weapon_damage_changed.emit()
	armor_changed.emit()
	SaveManager.save_character(self)


func get_damage() -> int:
	return weapon_damage


func get_total_damage() -> int:
	var total = get_damage()
	for companion_type in companions:
		if companion_type == "Wolf":
			total += WOLF_DAMAGE
	return total


func get_wolf_count() -> int:
	var count = 0
	for companion_type in companions:
		if companion_type == "Wolf":
			count += 1
	return count


func get_allay_count() -> int:
	var count = 0
	for companion_type in companions:
		if companion_type == "Allay":
			count += 1
	return count


func get_armor() -> int:
	return armor


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


func add_companion(companion_type: String) -> void:
	companions.append(companion_type)
	weapon_damage_changed.emit()
	SaveManager.save_character(self)


func load_state(a_display_name: String, a_portrait_id: String, a_max_hit_points: int, a_hit_points: int, a_damage: int, a_armor: int, a_companions: Array[String]) -> void:
	display_name = a_display_name
	portrait_id = a_portrait_id
	max_hit_points = a_max_hit_points
	_hit_points = clampi(a_hit_points, 0, a_max_hit_points)
	inventory.equip_weapon("", a_damage)
	inventory.equip_armor("", a_armor)
	companions = a_companions
