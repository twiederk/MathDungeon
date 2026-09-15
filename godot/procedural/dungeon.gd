class_name Dungeon

var root_node: Branch
var entrance: Vector2i
var floor_arr: Array[Vector2i] = []
var wall_arr: Array[Vector2i] = []


func _init(a_root_node: Branch, a_entrance: Vector2i, a_floor_arr: Array[Vector2i], a_wall_arr: Array[Vector2i]):
	root_node = a_root_node
	entrance = a_entrance
	floor_arr = a_floor_arr
	wall_arr = a_wall_arr
	
