class_name ProcGenWorld
extends WorldLevel


@export var seed_value: int = 0


const ATLAS_ID: int = 1
const TERRAIN_ID: int = 0
const WALL_TILE: Vector2i = Vector2i(2, 9)
const TILE_SIZE: int = 16
@warning_ignore("integer_division")
const TILE_SIZE_HALF: Vector2 = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

var dungeon_generator: DungeonGenerator = DungeonGenerator.new()


func _ready() -> void:
	generate_world(_resolve_seed())
	super._ready()


func _resolve_seed() -> int:
	if seed_value != GameSession.NO_SEED:
		return seed_value
	return GameSession.get_or_create_world_seed()


func generate_world(new_seed: int) -> void:
	_generate_seed(new_seed)
	var dungeon = dungeon_generator.generate_dungeon(Vector2i(100, 100), 6)
	_place_dungeon(dungeon)
	_place_player(dungeon)
	_place_enemies(dungeon)
	_place_items(dungeon)


func get_start_position() -> Vector2:
	return player.global_position


func _place_player(dungeon: Dungeon) -> void:
	player.global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(dungeon.start_position))


func _place_dungeon(dungeon: Dungeon) -> void:
	#for wall in dungeon.wall_arr:
		#tile_map_layer.set_cell(wall, 0, WALL_TILE)
	tile_map_layer.set_cells_terrain_connect(dungeon.floor_arr, ATLAS_ID, TERRAIN_ID)


func _place_enemies(dungeon: Dungeon) -> void:
	for enemy in dungeon.enemies:
		enemy.location = dungeon.id
		enemy.position = _world_position(enemy.position)
		enemies_root.add_child(enemy)

func _place_items(dungeon: Dungeon) -> void:
	for item in dungeon.items:
		item.position = _world_position(item.position)
		items_root.add_child(item)


func _world_position(local_position: Vector2) -> Vector2:
	return (local_position) * TILE_SIZE + TILE_SIZE_HALF


func _generate_seed(new_seed: int) -> void:
	if new_seed == 0:
		new_seed = randi()
	seed_value = new_seed
	seed(seed_value)
