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

const SPAWN_CHANCE_ITEM_EASY = 30
const SPAWN_CHANCE_ITEM_MEDIUM = 25
const SPAWN_CHANCE_ITEM_HARD = 20


func generate_items(root_node: Branch) -> Array[Item]:
	var items: Array[Item] = []
	var items_easy = [ARMOR_LEATHER_SCENE, ARMOR_PADDED_SCENE, WEAPON_KNIFE_SCENE, WEAPON_DAGGER_SCENE, HEALING_POTION_SCENE, HEALING_POTION_SCENE, HEALING_POTION_SCENE]
	var items_medium = [ARMOR_CHAIN_SCENE, ARMOR_SCALE_SCENE, WEAPON_SWORD_SCENE, HEALING_POTION_SCENE, HEALING_POTION_SCENE]
	var items_hard = [ARMOR_PLATE_SCENE, HEALING_POTION_SCENE]
	var item_pools = [items_easy, items_medium, items_hard]
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
