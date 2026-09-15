class_name ProcGenWorld
extends Main


const WORLD_TILE_SET: int = 0
const DUNGEON_GROUND_TILE: Vector2i = Vector2i(7, 0)
const DUNGEON_WALL_TILE: Vector2i = Vector2i(6, 0)

var dungeon_generator: DungeonGenerator = DungeonGenerator.new()


func _ready() -> void:
	var dungeon = dungeon_generator.generate_dungeon(Vector2i(20, 20))
	var offset = Vector2i(5, 5)
	_place_dungeon(dungeon, offset)
	
	dungeon = dungeon_generator.generate_dungeon(Vector2i(20, 20))
	offset = Vector2i(35, 5)
	_place_dungeon(dungeon, offset)
	
	dungeon = dungeon_generator.generate_dungeon(Vector2i(20, 20))
	offset = Vector2i(5, 35)
	_place_dungeon(dungeon, offset)
	
	dungeon = dungeon_generator.generate_dungeon(Vector2i(20, 20))
	offset = Vector2i(35, 35)
	_place_dungeon(dungeon, offset)
		
	super._ready()


func _place_dungeon(dungeon: Dungeon, offset: Vector2i) -> void:
	for floor_pos in dungeon.floor_arr:
		tile_map_layer.set_cell(floor_pos + offset, WORLD_TILE_SET, DUNGEON_GROUND_TILE)
	for wall_pos in dungeon.wall_arr:
		tile_map_layer.set_cell(wall_pos + offset, WORLD_TILE_SET, DUNGEON_WALL_TILE)
