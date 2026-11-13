class_name ProcGenWorld
extends WorldLevel


@export var seed_value: int = 0


const WORLD_TILE_SET: int = 0
const TILE_SIZE: int = 16
@warning_ignore("integer_division")
const TILE_SIZE_HALF: Vector2 = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
const DUNGEON_GROUND_TILE: Vector2i = Vector2i(2, 1)
const DUNGEON_WALL_TILE: Vector2i = Vector2i(2, 9)

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
	var dungeon = dungeon_generator.generate_dungeon(Vector2i(80, 80), 5)
	_place_dungeon(dungeon, Vector2i.ZERO)
	_place_player(dungeon, Vector2i.ZERO)
	_place_enemies(dungeon, Vector2i.ZERO)
	_place_items(dungeon, Vector2i.ZERO)


func get_start_position() -> Vector2:
	return player.global_position


func _place_player(dungeon: Dungeon, offset: Vector2i) -> void:
	player.global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(dungeon.start_position + offset))


func _place_dungeon(dungeon: Dungeon, offset: Vector2i) -> void:
	for floor_pos in dungeon.floor_arr:
		tile_map_layer.set_cell(floor_pos + offset, WORLD_TILE_SET, DUNGEON_GROUND_TILE)
	for wall_pos in dungeon.wall_arr:
		tile_map_layer.set_cell(wall_pos + offset, WORLD_TILE_SET, DUNGEON_WALL_TILE)


func _place_enemies(dungeon: Dungeon, offset: Vector2i) -> void:
	for enemy in dungeon.enemies:
		enemy.location = dungeon.id
		enemy.position = _world_position(enemy.position, offset)
		enemies_root.add_child(enemy)

func _place_items(dungeon: Dungeon, offset: Vector2i) -> void:
	for item in dungeon.items:
		item.position = _world_position(item.position, offset)
		items_root.add_child(item)


func _world_position(local_position: Vector2, offset: Vector2i) -> Vector2:
	return (local_position + Vector2(offset)) * TILE_SIZE + TILE_SIZE_HALF


func _generate_seed(new_seed: int) -> void:
	if new_seed == 0:
		new_seed = randi()
	seed_value = new_seed
	seed(seed_value)
