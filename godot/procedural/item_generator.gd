class_name ItemGenerator

# Items
const WOOD_HELMET_SCENE = preload("res://items/helmet_wood.tscn")
const STONE_HELMET_SCENE = preload("res://items/helmet_stone.tscn")
const STONE_SWORD_SCENE = preload("res://items/sword_stone.tscn")
const IRON_SWORD_SCENE = preload("res://items/sword_iron.tscn")
const HEALING_POTION_SCENE = preload("res://items/healing_potion.tscn")
const EYE_OF_ENDER_SCENE = preload("res://items/eye_of_ender.tscn")

const SPAWN_CHANCE_ITEM_EASY = 20
const SPAWN_CHANCE_ITEM_MEDIUM = 30


func generate_items(root_node: Branch) -> Array[Item]:
	var items: Array[Item] = []
	var items_easy = [WOOD_HELMET_SCENE, STONE_SWORD_SCENE]
	var items_medium = [STONE_HELMET_SCENE, IRON_SWORD_SCENE, HEALING_POTION_SCENE]

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

	var last_room = rooms[-1]
	var eye_of_ender = EYE_OF_ENDER_SCENE.instantiate() as Item
	eye_of_ender.position = last_room.get_center()
	items.append(eye_of_ender)

	return items
