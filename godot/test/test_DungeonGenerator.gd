extends GutTest

var dungeon_generator: DungeonGenerator = null
var dungeon = null
var easy_enemies: Array[PackedScene] = []
var medium_enemies: Array[PackedScene] = []


func before_each():
	dungeon_generator = DungeonGenerator.new()
	var level_one_pools := EnemyGenerator.get_enemy_pools(1)
	easy_enemies.assign(level_one_pools.easy)
	medium_enemies.assign(level_one_pools.medium)


func test_generate():
	
	# act
	dungeon = dungeon_generator.generate_dungeon(_make_level_config(Vector2i(20, 20), 3, 0))
	
	# assert
	assert_not_null(dungeon.root_node, "Dungeon root node should not be null")
	
	# tear down
	for item in dungeon.items:
		item.free()
		
	for enemy in dungeon.enemies:
		enemy.free()


func test_generate_configures_stairs_at_dungeon_endpoints():
	# act
	var generated_dungeon = dungeon_generator.generate_dungeon(_make_level_config(Vector2i(20, 20), 3, 0))

	# assert
	assert_eq(generated_dungeon.stairs_up_position, generated_dungeon.start_position)
	assert_eq(generated_dungeon.stairs_down_position, generated_dungeon.end_position)
	assert_does_not_have(generated_dungeon.floor_arr, Vector2i(0, 1))
	assert_has(generated_dungeon.wall_arr, Vector2i(0, 1))

	# tear down
	for item in generated_dungeon.items:
		item.free()
	for enemy in generated_dungeon.enemies:
		enemy.free()


func test_progression_sizes_generate_usable_stairs(parameters = use_parameters([
	[Vector2i(40, 23), 3],
	[Vector2i(60, 40), 4],
	[Vector2i(100, 80), 5],
	[Vector2i(120, 120), 5]
])):
	# arrange
	var level_size = parameters[0]
	var splits = parameters[1]
	var expected_leaf_count = int(pow(2, splits + 1))

	# act
	var generated_dungeon = dungeon_generator.generate_dungeon(_make_level_config(level_size, splits, 4711))

	# assert
	var leaves = generated_dungeon.root_node.get_leaves()
	assert_eq(generated_dungeon.root_node.size, level_size)
	assert_eq(leaves.size(), expected_leaf_count)
	for room in leaves:
		assert_true(room is Room)
	assert_ne(generated_dungeon.stairs_up_position, generated_dungeon.stairs_down_position)
	assert_has(generated_dungeon.floor_arr, generated_dungeon.stairs_up_position)
	assert_has(generated_dungeon.floor_arr, generated_dungeon.stairs_down_position)

	# tear down
	_free_generated_content(generated_dungeon)


func test_progression_regeneration_is_deterministic():
	# arrange
	var first_dungeon = dungeon_generator.generate_dungeon(_make_level_config(Vector2i(40, 23), 3, 4711))

	# act
	var revisited_dungeon = dungeon_generator.generate_dungeon(_make_level_config(Vector2i(40, 23), 3, 4711))

	# assert
	assert_eq(revisited_dungeon.floor_arr, first_dungeon.floor_arr)
	assert_eq(revisited_dungeon.wall_arr, first_dungeon.wall_arr)
	assert_eq(revisited_dungeon.stairs_up_position, first_dungeon.stairs_up_position)
	assert_eq(revisited_dungeon.stairs_down_position, first_dungeon.stairs_down_position)
	assert_eq(_content_signature(revisited_dungeon.enemies), _content_signature(first_dungeon.enemies))
	assert_eq(_content_signature(revisited_dungeon.items), _content_signature(first_dungeon.items))

	# tear down
	_free_generated_content(first_dungeon)
	_free_generated_content(revisited_dungeon)


func _content_signature(nodes: Array) -> Array:
	var signature: Array = []
	for node in nodes:
		signature.append([node.scene_file_path, node.position])
	return signature


func _make_level_config(size: Vector2i, splits: int, seed_value: int) -> LevelConfig:
	return LevelConfig.new(seed_value, size, splits)


func _free_generated_content(generated_dungeon: Dungeon) -> void:
	for item in generated_dungeon.items:
		item.free()
	for enemy in generated_dungeon.enemies:
		enemy.free()


func test_room_footprint_matches_carved_floors():
	# arrange
	var room = Room.new(Vector2i(3, 5), Vector2i(3, 3))
	var expected: Array[Vector2i] = [Vector2i(4, 6), Vector2i(4, 7), Vector2i(5, 6), Vector2i(5, 7)]

	# act
	var floors = dungeon_generator._place_rooms(room)

	# assert
	assert_eq(floors, expected)
	assert_eq(room.get_room_rect(), Rect2i(4, 6, 2, 2))


func test_entrance_spawn_on_each_side(parameters = use_parameters([
	[Vector2i(10, 12), Vector2i(11, 12)],
	[Vector2i(14, 12), Vector2i(13, 12)],
	[Vector2i(12, 10), Vector2i(12, 11)],
	[Vector2i(12, 14), Vector2i(12, 13)]
])):
	# arrange
	var room = Room.new(Vector2i(10, 10), Vector2i(4, 4))
	var floors = dungeon_generator._place_rooms(room)
	floors.append(parameters[0])

	# act
	dungeon_generator._configure_room_entrances([room], floors)

	# assert
	var entrances = room.get_entrances()
	assert_eq(entrances.size(), 1)
	assert_eq(entrances[0], parameters[1])


func test_room_returns_multiple_distinct_entrances():
	# arrange
	var room = Room.new(Vector2i(10, 10), Vector2i(4, 4))
	var floors = dungeon_generator._place_rooms(room)
	floors.append(Vector2i(10, 11))
	floors.append(Vector2i(11, 10))
	floors.append(Vector2i(14, 12))
	var expected: Array[Vector2i] = [Vector2i(11, 11), Vector2i(13, 12)]

	# act
	dungeon_generator._configure_room_entrances([room], floors)

	# assert
	var entrances = room.get_entrances()
	assert_eq(entrances, expected)


func test_spawn_falls_back_to_room_center():
	# arrange
	var room = Room.new(Vector2i(10, 10), Vector2i(4, 4))

	# act
	var spawn_position = dungeon_generator.enemy_generator._find_spawn_position(room)

	# assert
	assert_eq(spawn_position, Vector2i(12, 12))


func test_room_tier_boundaries(parameters = use_parameters([
	[0.0, Generator.Tier.EASY],
	[Generator.EASY_TIER_END_PROGRESS, Generator.Tier.EASY],
	[0.5001, Generator.Tier.MEDIUM],
	[0.7499, Generator.Tier.MEDIUM],
	[Generator.HARD_TIER_START_PROGRESS, Generator.Tier.HARD],
	[1.0, Generator.Tier.HARD]
])):
	# arrange
	var generator := Generator.new()
	var room_progress = parameters[0]
	var expected_tier = parameters[1]

	# act
	var tier = generator._get_room_tier(room_progress)

	# assert
	assert_eq(tier, expected_tier)


func test_place_enemies():
	# arrange
	var root_node = Branch.new(Vector2i.ZERO, Vector2i(20, 20))
	var paths: Array[Dictionary] = []
	seed(4711)
	root_node.split(3, paths)
	var floors = dungeon_generator._place_rooms(root_node)
	dungeon_generator._place_paths(paths, floors)
	dungeon_generator._configure_room_entrances(root_node.get_leaves(), floors)
	
	# act
	var enemies = dungeon_generator._place_enemies(root_node, easy_enemies, medium_enemies, medium_enemies)
	
	# assert
	assert_true(enemies.size() > 0, "Enemies should be placed in the dungeon")
	for enemy in enemies:
		var tile = Vector2i(enemy.position)
		assert_has(floors, tile)
		var room_found = false
		for room in root_node.get_leaves():
			var room_rect: Rect2i = room.get_room_rect()
			if not room_rect.has_point(tile):
				continue
			room_found = true
			var next_to_entrance = false
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = tile + direction
				if not room_rect.has_point(neighbor) and neighbor in floors:
					next_to_entrance = true
			assert_true(next_to_entrance, "Enemy should be next to a room entrance")
		assert_true(room_found, "Enemy should be inside a room")

	# tear down
	for enemy in enemies:
		enemy.free()


func test_empty_enemy_pools_skip_spawns_safely():
	# arrange
	var empty_pool: Array[PackedScene] = []
	var root_node = Branch.new(Vector2i.ZERO, Vector2i(20, 20))
	var paths: Array[Dictionary] = []
	root_node.split(3, paths)
	seed(4711)

	# act
	var enemies = dungeon_generator._place_enemies(root_node, empty_pool, empty_pool, empty_pool)

	# assert
	assert_true(enemies.is_empty())


func test_place_items():
	# arrange
	var root_node = Branch.new(Vector2i.ZERO, Vector2i(20, 20))
	var paths: Array[Dictionary] = []
	root_node.split(3, paths)
	
	# act
	var items = dungeon_generator._place_items(root_node)
	
	# assert
	assert_true(items.size() > 0, "Items should be placed in the dungeon")
	
	# tear down
	for item in items:
		item.free()
