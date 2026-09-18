class_name DungeonGenerator


# Items
const WOOD_HELMET_SCENE = preload("res://items/helmet_wood.tscn")
const STONE_HELMET_SCENE = preload("res://items/helmet_stone.tscn")
const STONE_SWORD_SCENE = preload("res://items/sword_stone.tscn")
const IRON_SWORD_SCENE = preload("res://items/sword_iron.tscn")
const HEALING_POTION_SCENE = preload("res://items/healing_potion.tscn")
const EYE_OF_ENDER_SCENE = preload("res://items/eye_of_ender.tscn")

const SPAWN_CHANCE_ITEM_EASY = 20
const SPAWN_CHANCE_ITEM_MEDIUM = 30

const ENTRANCE = Vector2i(0, 1)

var enemy_generator = EnemyGenerator.new()


func generate_dungeon(size: Vector2i) -> Dungeon:
	var root_node  = Branch.new(Vector2i.ZERO, size)
	var paths: Array[Dictionary] = []
	root_node.split(3, paths)
	var floor_arr = _place_rooms(root_node)
	_place_paths(paths, floor_arr)
	var enemies = _place_enemies(root_node)
	var items = _place_items(root_node)
	var entrance = _place_entrance(floor_arr)
	var wall_arr = _place_walls(size, floor_arr)
	return Dungeon.new(root_node, entrance, floor_arr, wall_arr, enemies, items)


func _place_rooms(root_node: Branch) -> Array[Vector2i]:
	var floor_arr: Array[Vector2i] = []
	for leaf in root_node.get_leaves():
		var padding = Vector4i.ZERO
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				if not is_inside_padding(x, y, leaf, padding):
					var curr_pos = Vector2i(x + leaf.position.x, y + leaf.position.y)
					floor_arr.append(curr_pos)
	return floor_arr


func _place_paths(paths: Array[Dictionary], floor_arr: Array[Vector2i]) -> void:
	for path in paths:
		if path['left'].y == path['right'].y:
			for i in range(path['right'].x - path['left'].x):
				var curr_pos = Vector2i(path['left'].x+i,path['left'].y)
				floor_arr.append(curr_pos)
		else:
			for i in range(path['right'].y - path['left'].y):
				var curr_pos = Vector2i(path['left'].x,path['left'].y+i)
				floor_arr.append(curr_pos)


func _place_entrance(floor_arr: Array[Vector2i]) -> Vector2i:
		floor_arr.append(ENTRANCE)
		return ENTRANCE


func _place_walls(size: Vector2i, floor_arr: Array[Vector2i]) -> Array[Vector2i]:
	var wall_arr: Array[Vector2i] = []
	for x in range(size.x + 1):
		for y in range(size.y + 1):
			var curr_pos = Vector2i(x, y)
			if not curr_pos in floor_arr:
				wall_arr.append(curr_pos)
	return wall_arr


func is_inside_padding(x, y, leaf, padding) -> bool:
	return x <= padding.x or y <= padding.y or x >= leaf.size.x - padding.z or y >= leaf.size.y - padding.w


func _place_enemies(root_node: Branch) -> Array[Enemy]:
	return enemy_generator.generate_enemies(root_node)


func _place_items(root_node: Branch) -> Array[Item]:
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
