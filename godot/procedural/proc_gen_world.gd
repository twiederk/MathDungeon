class_name ProcGenWorld
extends Node2D


const WORLD_TILE_SET = 0
const DUNGEON_GROUND_TILE = Vector2i(8, 0)

var root_node: Branch
var tile_size: int = 32
var paths: Array = []

@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	root_node  = Branch.new(Vector2i(0, 0), Vector2i(20, 20))
	root_node.split(3, paths)

	for leaf in root_node.get_leaves():
		var padding = Vector4i.ZERO
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				if not is_inside_padding(x, y, leaf, padding):
					var curr_pos = Vector2i(x + leaf.position.x, y + leaf.position.y)
					tile_map_layer.set_cell(curr_pos, WORLD_TILE_SET, DUNGEON_GROUND_TILE)

	for path in paths:
		if path['left'].y == path['right'].y:
			for i in range(path['right'].x - path['left'].x):
				var curr_pos = Vector2i(path['left'].x+i,path['left'].y)
				tile_map_layer.set_cell(curr_pos, WORLD_TILE_SET, DUNGEON_GROUND_TILE)
		else:
			for i in range(path['right'].y - path['left'].y):
				var curr_pos = Vector2i(path['left'].x,path['left'].y+i)
				tile_map_layer.set_cell(curr_pos, WORLD_TILE_SET, DUNGEON_GROUND_TILE)
	queue_redraw()


func is_inside_padding(x, y, leaf, padding):
	return x <= padding.x or y <= padding.y or x >= leaf.size.x - padding.z or y >= leaf.size.y - padding.w


func _draw() -> void:
	for leaf in root_node.get_leaves():
		draw_rect(
			Rect2(
				leaf.position.x * tile_size,
				leaf.position.y * tile_size,
				leaf.size.x * tile_size,
				leaf.size.y * tile_size
			), 
			Color.GREEN,
			false
		)
