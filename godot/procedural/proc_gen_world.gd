class_name ProcGenWorld
extends Node2D


const WORLD_TILE_SET = 0
const DUNGEON_GROUND_TILE = Vector2i(7, 0)

var tile_size: int = 32
var dungeon_generator = DungeonGenerator.new()

@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	var floor_arr = dungeon_generator.generate_dungeon()

	for floor_pos in floor_arr:
		tile_map_layer.set_cell(floor_pos, WORLD_TILE_SET, DUNGEON_GROUND_TILE)



#func _draw() -> void:
	#for leaf in root_node.get_leaves():
		#draw_rect(
			#Rect2(
				#leaf.position.x * tile_size,
				#leaf.position.y * tile_size,
				#leaf.size.x * tile_size,
				#leaf.size.y * tile_size
			#), 
			#Color.GREEN,
			#false
		#)
