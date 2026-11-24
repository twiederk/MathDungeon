class_name ItemGenerator
extends Generator


const ARMOR_LEATHER_SCENE = preload("res://procedural/items/armor_leather.tscn")
const ARMOR_PADDED_SCENE = preload("res://procedural/items/armor_padded.tscn")
const ARMOR_CHAIN_SCENE = preload("res://procedural/items/armor_chain.tscn")
const ARMOR_SCALE_SCENE = preload("res://procedural/items/armor_scale.tscn")
const ARMOR_PLATE_SCENE = preload("res://procedural/items/armor_plate.tscn")

const WEAPON_KNIFE_SCENE = preload("res://procedural/items/weapon_knife.tscn")
const WEAPON_DAGGER_SCENE = preload("res://procedural/items/weapon_dagger.tscn")
const WEAPON_SWORD_SCENE = preload("res://procedural/items/weapon_sword.tscn")

const HEALING_POTION_SCENE = preload("res://procedural/items/healing_potion.tscn")
const ARMOR_LEATHER_RESOURCE = preload("res://procedural/items/armor_leather.tres")
const ARMOR_PADDED_RESOURCE = preload("res://procedural/items/armor_padded.tres")
const ARMOR_CHAIN_RESOURCE = preload("res://procedural/items/armor_chain.tres")
const ARMOR_SCALE_RESOURCE = preload("res://procedural/items/armor_scale.tres")
const ARMOR_PLATE_RESOURCE = preload("res://procedural/items/armor_plate.tres")
const WEAPON_KNIFE_RESOURCE = preload("res://procedural/items/weapon_knife.tres")
const WEAPON_DAGGER_RESOURCE = preload("res://procedural/items/weapon_dagger.tres")
const WEAPON_SWORD_RESOURCE = preload("res://procedural/items/weapon_sword.tres")
const HEALING_POTION_RESOURCE = preload("res://procedural/items/healing_potion_good.tres")

const SPAWN_CHANCE_ITEM_EASY = 30
const SPAWN_CHANCE_ITEM_MEDIUM = 25
const SPAWN_CHANCE_ITEM_HARD = 20
const ITEM_CATALOG := [
	{"scene": ARMOR_LEATHER_SCENE, "resource": ARMOR_LEATHER_RESOURCE},
	{"scene": ARMOR_PADDED_SCENE, "resource": ARMOR_PADDED_RESOURCE},
	{"scene": ARMOR_CHAIN_SCENE, "resource": ARMOR_CHAIN_RESOURCE},
	{"scene": ARMOR_SCALE_SCENE, "resource": ARMOR_SCALE_RESOURCE},
	{"scene": ARMOR_PLATE_SCENE, "resource": ARMOR_PLATE_RESOURCE},
	{"scene": WEAPON_KNIFE_SCENE, "resource": WEAPON_KNIFE_RESOURCE},
	{"scene": WEAPON_DAGGER_SCENE, "resource": WEAPON_DAGGER_RESOURCE},
	{"scene": WEAPON_SWORD_SCENE, "resource": WEAPON_SWORD_RESOURCE},
	{"scene": HEALING_POTION_SCENE, "resource": HEALING_POTION_RESOURCE},
]


func generate_items(root_node: Branch, dungeon_level: int) -> Array[Item]:
	var items: Array[Item] = []
	var effective_level := clampi(dungeon_level, 1, _get_max_item_level())
	var item_pools: Array = [
		_get_item_pool_for_level(effective_level, Generator.Tier.EASY),
		_get_item_pool_for_level(effective_level, Generator.Tier.MEDIUM),
		_get_item_pool_for_level(effective_level, Generator.Tier.HARD)
	]
	var spawn_chances = [SPAWN_CHANCE_ITEM_EASY, SPAWN_CHANCE_ITEM_MEDIUM, SPAWN_CHANCE_ITEM_HARD]

	var rooms = root_node.get_leaves()
	var number_of_rooms = rooms.size()
	for room_index in range(1, number_of_rooms - 1):
		var room_progress = float(room_index) / number_of_rooms
		var item_tier = _get_room_tier(room_progress)
		var item_scenes: Array = item_pools[item_tier]
		var spawn_chance: int = spawn_chances[item_tier]

		if randi_range(0, 100) > spawn_chance:
			continue
		var room = rooms[room_index]
		var item_scene = item_scenes.pick_random()
		var item = item_scene.instantiate() as Item
		item.position = room.get_center()
		items.append(item)

	return items


func _get_item_pool(dungeon_level: int, tier: int) -> Array[PackedScene]:
	var effective_level := clampi(dungeon_level, 1, _get_max_item_level())
	return _get_item_pool_for_level(effective_level, tier)


func _get_item_pool_for_level(effective_level: int, tier: int) -> Array[PackedScene]:
	var item_pool: Array[PackedScene] = []
	if tier < Generator.Tier.EASY or tier > Generator.Tier.HARD:
		return item_pool
	var eligible_levels := _get_eligible_content_levels(effective_level, tier)
	for item_definition in ITEM_CATALOG:
		var item_resource: Resource = item_definition.resource
		var item_level := _get_item_level(item_resource)
		if item_level == GoodResource.LEVEL_ALL_DUNGEON_LEVELS or eligible_levels.has(item_level):
			var item_scene: PackedScene = item_definition.scene
			item_pool.append(item_scene)
	return item_pool


func _get_item_level(item_resource: Resource) -> int:
	if item_resource is ArmorResource:
		return (item_resource as ArmorResource).armor
	if item_resource is WeaponResource:
		return (item_resource as WeaponResource).damage
	if item_resource is GoodResource:
		return (item_resource as GoodResource).level
	return -1


func _get_max_item_level() -> int:
	var max_level := 1
	for item_definition in ITEM_CATALOG:
		var item_resource: Resource = item_definition.resource
		var item_level := _get_item_level(item_resource)
		if item_level != GoodResource.LEVEL_ALL_DUNGEON_LEVELS:
			max_level = maxi(max_level, item_level)
	return max_level
