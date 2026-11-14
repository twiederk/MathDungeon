class_name Dungeon

var id: String = ""
var root_node: Branch
var entrance: Vector2i
var start_position: Vector2i
var end_position: Vector2i
var floor_arr: Array[Vector2i] = []
var wall_arr: Array[Vector2i] = []
var enemies: Array[Enemy] = []
var items: Array[Item] = []


func _init(a_root_node: Branch, a_entrance: Vector2i, a_start_position: Vector2i, a_end_position: Vector2i, a_floor_arr: Array[Vector2i], a_wall_arr: Array[Vector2i], a_enemies: Array[Enemy], a_items: Array[Item]):
	root_node = a_root_node
	entrance = a_entrance
	start_position = a_start_position
	end_position = a_end_position
	floor_arr = a_floor_arr
	wall_arr = a_wall_arr
	enemies = a_enemies
	items = a_items
