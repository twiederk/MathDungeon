class_name DungeonGenerator


func generate_dungeon() -> Dungeon:
	var root_node  = Branch.new(Vector2i(0, 0), Vector2i(20, 20))
	var paths: Array = []
	root_node.split(3, paths)

	var floor_arr: Array[Vector2i] = []
	for leaf in root_node.get_leaves():
		var padding = Vector4i.ZERO
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				if not is_inside_padding(x, y, leaf, padding):
					var curr_pos = Vector2i(x + leaf.position.x, y + leaf.position.y)
					floor_arr.append(curr_pos)

	for path in paths:
		if path['left'].y == path['right'].y:
			for i in range(path['right'].x - path['left'].x):
				var curr_pos = Vector2i(path['left'].x+i,path['left'].y)
				floor_arr.append(curr_pos)
		else:
			for i in range(path['right'].y - path['left'].y):
				var curr_pos = Vector2i(path['left'].x,path['left'].y+i)
				floor_arr.append(curr_pos)
				
	return Dungeon.new(root_node, floor_arr)


func is_inside_padding(x, y, leaf, padding):
	return x <= padding.x or y <= padding.y or x >= leaf.size.x - padding.z or y >= leaf.size.y - padding.w
