class_name DungeonGenerator


const ENTRANCE = Vector2i(0, 1)

var floor_arr: Array[Vector2i]
var wall_arr: Array[Vector2i]
var entrance: Vector2i


func generate_dungeon(size: Vector2i) -> Dungeon:
	floor_arr = []
	var root_node  = Branch.new(Vector2i.ZERO, size)
	var paths: Array[Dictionary] = []
	root_node.split(3, paths)
	_place_rooms(root_node)
	_place_paths(paths)
	_place_entrance()
	_place_walls(size)
	return Dungeon.new(root_node, entrance, floor_arr, wall_arr)


func _place_rooms(root_node: Branch) -> void:
	for leaf in root_node.get_leaves():
		var padding = Vector4i.ZERO
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				if not is_inside_padding(x, y, leaf, padding):
					var curr_pos = Vector2i(x + leaf.position.x, y + leaf.position.y)
					floor_arr.append(curr_pos)


func _place_paths(paths: Array[Dictionary]) -> void:
	for path in paths:
		if path['left'].y == path['right'].y:
			for i in range(path['right'].x - path['left'].x):
				var curr_pos = Vector2i(path['left'].x+i,path['left'].y)
				floor_arr.append(curr_pos)
		else:
			for i in range(path['right'].y - path['left'].y):
				var curr_pos = Vector2i(path['left'].x,path['left'].y+i)
				floor_arr.append(curr_pos)


func _place_entrance() -> void:
		floor_arr.append(ENTRANCE)


func _place_walls(size: Vector2i) -> void:
	for x in range(size.x + 1):
		for y in range(size.y + 1):
			var curr_pos = Vector2i(x, y)
			if not curr_pos in floor_arr:
				wall_arr.append(curr_pos)


func is_inside_padding(x, y, leaf, padding) -> bool:
	return x <= padding.x or y <= padding.y or x >= leaf.size.x - padding.z or y >= leaf.size.y - padding.w
