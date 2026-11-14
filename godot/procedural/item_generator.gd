class_name ItemGenerator


const WOOD_HELMET_SCENE = preload("res://procedural/items/helmet_wood.tscn")

const WEAPON_KNIFE_SCENE = preload("res://procedural/items/weapon_knife.tscn")
const WEAPON_DAGGER_SCENE = preload("res://procedural/items/weapon_dagger.tscn")
const WEAPON_SWORD_SCENE = preload("res://procedural/items/weapon_sword.tscn")

const HEALING_POTION_SCENE = preload("res://procedural/items/healing_potion.tscn")

const SPAWN_CHANCE_ITEM_EASY = 20
const SPAWN_CHANCE_ITEM_MEDIUM = 30


func generate_items(root_node: Branch) -> Array[Item]:
	var items: Array[Item] = []
	var items_easy = [WOOD_HELMET_SCENE, WEAPON_KNIFE_SCENE, WEAPON_DAGGER_SCENE]
	var items_medium = [WOOD_HELMET_SCENE, WEAPON_SWORD_SCENE, HEALING_POTION_SCENE]

	var rooms = root_node.get_leaves()
	var number_of_rooms = rooms.size()
	@warning_ignore("integer_division")
	var half_number_of_rooms: int = number_of_rooms / 2

	for room_index in range(1, half_number_of_rooms + 1):
		if randi_range(0, 100) > SPAWN_CHANCE_ITEM_EASY:
			continue
		var room = rooms[room_index]
		var item_scene = items_easy.pick_random()
		var item = item_scene.instantiate() as Item
		item.position = room.get_center()
		items.append(item)

	for room_index in range(half_number_of_rooms + 1, number_of_rooms - 1):
		if randi_range(0, 100) > SPAWN_CHANCE_ITEM_MEDIUM:
			continue
		var room = rooms[room_index]
		var item_scene = items_medium.pick_random()
		var item = item_scene.instantiate() as Item
		item.position = room.get_center()
		items.append(item)

	return items
