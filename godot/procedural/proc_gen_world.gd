class_name ProcGenWorld
extends WorldLevel


@export var seed_value: int = 0


const PROCEDURAL_WORLD_SCENE_PATH := "res://procedural/proc_gen_world.tscn"
const START_MENU_SCENE_PATH := "res://gui/start_gui.tscn"
const STAIRS_UP_SCENE: PackedScene = preload("res://procedural/stairs_up.tscn")
const STAIRS_DOWN_SCENE: PackedScene = preload("res://procedural/stairs_down.tscn")
const DUNGEON_ATLAS_ID: int = 1
const STONE_TERRAIN_ID: int = 0
const SAND_TERRAIN_ID: int = 1
const TILE_SIZE: int = 16
@warning_ignore("integer_division")
const TILE_SIZE_HALF: Vector2 = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

var dungeon_generator: DungeonGenerator = DungeonGenerator.new()
var dungeon: Dungeon
var transition_started: bool = false

@onready var locations_root: Node2D = $Locations


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
	dungeon = dungeon_generator.generate_dungeon(level_config["size"], 3, seed_value)
	_place_dungeon(dungeon)
	_place_stairs(dungeon)
	_place_player(dungeon)
	_place_enemies(dungeon)
	_place_items(dungeon)


func get_start_position() -> Vector2:
	return player.global_position


func _place_player(generated_dungeon: Dungeon) -> void:
	var spawn_position := generated_dungeon.start_position
	if GameSession.procedural_spawn_at_end:
		spawn_position = generated_dungeon.end_position
	player.global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(spawn_position))


func _place_stairs(generated_dungeon: Dungeon) -> void:
	var spawn_at_up_stairs := not GameSession.procedural_spawn_at_end
	_add_stairs(STAIRS_UP_SCENE, generated_dungeon.start_position, spawn_at_up_stairs)
	_add_stairs(STAIRS_DOWN_SCENE, generated_dungeon.end_position, GameSession.procedural_spawn_at_end)


func _add_stairs(stairs_scene: PackedScene, tile_position: Vector2i, starts_disarmed: bool) -> void:
	var stairs = stairs_scene.instantiate()
	stairs.position = locations_root.to_local(tile_map_layer.to_global(tile_map_layer.map_to_local(tile_position)))
	stairs.set("starts_disarmed", starts_disarmed)
	stairs.activated.connect(_on_stairs_activated)
	locations_root.add_child(stairs)


func _on_stairs_activated(goes_down: bool) -> void:
	if transition_started:
		return
	if _handle_stair_transition(goes_down):
		transition_started = true
		_finish_procedural_run()
		return
	transition_started = true
	get_tree().call_deferred("change_scene_to_file", PROCEDURAL_WORLD_SCENE_PATH)


func _handle_stair_transition(goes_down: bool) -> bool:
	if goes_down:
		var next_level_index := GameSession.procedural_level_index + 1
		var next_level_config := GameSession.get_or_create_procedural_level_config(next_level_index)
		if next_level_config.is_empty():
			return false
		GameSession.procedural_level_index = next_level_index
		GameSession.procedural_spawn_at_end = false
		return false

	if GameSession.procedural_level_index == GameSession.FIRST_PROCEDURAL_LEVEL:
		return true

	GameSession.procedural_level_index -= 1
	GameSession.procedural_spawn_at_end = true
	return false


func _finish_procedural_run() -> void:
	GameSession.display_state = GameSession.DisplayState.NONE
	GameSession.stop_run()
	var has_highscore := HighscoreManager.is_highscore(GameSession.score)
	var destination := _resolve_procedural_run_end_scene(has_highscore)
	get_tree().call_deferred("change_scene_to_file", destination)


func _resolve_procedural_run_end_scene(has_highscore: bool) -> String:
	if has_highscore:
		return NAME_ENTRY_DIALOG_PATH
	return START_MENU_SCENE_PATH


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
