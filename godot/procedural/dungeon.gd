class_name Dungeon

var floor_arr: Array[Vector2i] = []
var root_node: Branch


func _init(a_root_node: Branch, a_floor_arr: Array[Vector2i]):
	root_node = a_root_node
	floor_arr = a_floor_arr
	
