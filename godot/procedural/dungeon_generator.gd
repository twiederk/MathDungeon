class_name DungeonGenerator


var enemy_generator = EnemyGenerator.new()
var item_generator = ItemGenerator.new()


func generate_dungeon(level_config: LevelConfig) -> Dungeon:
	if level_config.seed_value != 0:
		seed(level_config.seed_value)
	var root_node  = Branch.new(Vector2i.ZERO, level_config.size)
	var paths: Array[Dictionary] = []
	root_node.split(level_config.splits, paths)
	var rooms := root_node.get_leaves()
	var start_position := rooms[0].get_center()
	var end_position := rooms[rooms.size() - 1].get_center()
	var floor_arr = _place_rooms(root_node)
	_place_paths(paths, floor_arr)
	_configure_room_entrances(rooms, floor_arr)
	var enemies = _place_enemies(root_node, level_config.easy_enemies, level_config.medium_enemies)
	var items = _place_items(root_node)
	var wall_arr = _place_walls(level_config.size, floor_arr)
	var dungeon := Dungeon.new(root_node, start_position, end_position, floor_arr, wall_arr, enemies, items)
	_configure_stairs(dungeon)
	return dungeon


func _configure_stairs(dungeon: Dungeon) -> void:
	dungeon.stairs_up_position = dungeon.start_position
	dungeon.stairs_down_position = dungeon.end_position


func _configure_room_entrances(rooms: Array[Room], floor_arr: Array[Vector2i]) -> void:
	var floors: Dictionary = {}
	for floor_position in floor_arr:
		floors[floor_position] = true
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for room in rooms:
		room.entrances.clear()
		var room_rect := room.get_room_rect()
		for tile in room.get_floor_tiles():
			for direction in directions:
				var neighbor := tile + direction
				if not room_rect.has_point(neighbor) and floors.has(neighbor):
					room.entrances.append(tile)
					break


func _place_rooms(root_node: Branch) -> Array[Vector2i]:
	var floor_arr: Array[Vector2i] = []
	for leaf in root_node.get_leaves():
		var room_rect := leaf.get_room_rect()
		for x in range(room_rect.position.x, room_rect.end.x):
			for y in range(room_rect.position.y, room_rect.end.y):
				floor_arr.append(Vector2i(x, y))
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


func _place_enemies(root_node: Branch, easy_enemies: Array[PackedScene], medium_enemies: Array[PackedScene]) -> Array[Enemy]:
	return enemy_generator.generate_enemies(root_node, easy_enemies, medium_enemies)


func _place_items(root_node: Branch) -> Array[Item]:
	return item_generator.generate_items(root_node)
