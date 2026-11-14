class_name ProcGenWorld
extends WorldLevel


@export var seed_value: int = 0


const DUNGEON_ATLAS_ID: int = 1
const STONE_TERRAIN_ID: int = 0
const SAND_TERRAIN_ID: int = 1
const TILE_SIZE: int = 16
@warning_ignore("integer_division")
const TILE_SIZE_HALF: Vector2 = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

var dungeon_generator: DungeonGenerator = DungeonGenerator.new()
var dungeon: Dungeon


func _ready() -> void:
	generate_world(_resolve_level_config())
	super._ready()


func _resolve_level_config() -> Dictionary:
	var level_config := GameSession.get_or_create_procedural_level_config(GameSession.procedural_level_index)
	if seed_value != GameSession.NO_SEED:
		level_config["seed"] = seed_value
	return level_config


func _resolve_seed() -> int:
	if seed_value != GameSession.NO_SEED:
		return seed_value
	return GameSession.get_or_create_procedural_level_config(GameSession.procedural_level_index)["seed"]


func generate_world(level_config: Dictionary) -> void:
	seed_value = level_config["seed"]
	dungeon = dungeon_generator.generate_dungeon(level_config["size"], 6, seed_value)
	_place_dungeon(dungeon)
	_place_player(dungeon)
	_place_enemies(dungeon)
	_place_items(dungeon)


func get_start_position() -> Vector2:
	return player.global_position


func _place_player(generated_dungeon: Dungeon) -> void:
	player.global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(generated_dungeon.start_position))


func _place_dungeon(generated_dungeon: Dungeon) -> void:
	tile_map_layer.set_cells_terrain_connect(generated_dungeon.wall_arr, DUNGEON_ATLAS_ID, STONE_TERRAIN_ID)
	tile_map_layer.set_cells_terrain_connect(generated_dungeon.floor_arr, DUNGEON_ATLAS_ID, SAND_TERRAIN_ID)


func _place_enemies(generated_dungeon: Dungeon) -> void:
	for enemy in generated_dungeon.enemies:
		enemy.location = generated_dungeon.id
		enemy.position = _world_position(enemy.position)
		enemies_root.add_child(enemy)

func _place_items(generated_dungeon: Dungeon) -> void:
	for item in generated_dungeon.items:
		item.position = _world_position(item.position)
		items_root.add_child(item)


func _world_position(local_position: Vector2) -> Vector2:
	return (local_position) * TILE_SIZE + TILE_SIZE_HALF
