extends GutTest

var dungeon_generator: DungeonGenerator = null
var dungeon = null


func before_each():
	dungeon_generator = DungeonGenerator.new()


func test_generate():
	
	# act
	dungeon = dungeon_generator.generate_dungeon(Vector2i(20, 20))
	
	# assert
	assert_not_null(dungeon.root_node, "Dungeon root node should not be null")
	
	# tear down
	for item in dungeon.items:
		item.free()
		
	for enemy in dungeon.enemies:
		enemy.free()


func test_generate_configures_stairs_at_dungeon_endpoints():
	# act
	var generated_dungeon = dungeon_generator.generate_dungeon(Vector2i(20, 20))

	# assert
	assert_eq(generated_dungeon.stairs_up_position, generated_dungeon.start_position)
	assert_eq(generated_dungeon.stairs_down_position, generated_dungeon.end_position)

	# tear down
	for item in generated_dungeon.items:
		item.free()
	for enemy in generated_dungeon.enemies:
		enemy.free()


func test_place_entrance():
	# arrange
	var floor_arr: Array[Vector2i] = []
	
	# act
	var entrance = dungeon_generator._place_entrance(floor_arr)
	
	# assert
	assert_true(entrance == Vector2i(0, 1), "Entrance should be placed at (0, 1)")


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
	var generated_dungeon = dungeon_generator.generate_dungeon(level_size, splits, 4711)

	# assert
	var leaves = generated_dungeon.root_node.get_leaves()
	assert_eq(generated_dungeon.root_node.size, level_size)
	assert_eq(leaves.size(), expected_leaf_count)
	assert_ne(generated_dungeon.stairs_up_position, generated_dungeon.stairs_down_position)
	assert_has(generated_dungeon.floor_arr, generated_dungeon.stairs_up_position)
	assert_has(generated_dungeon.floor_arr, generated_dungeon.stairs_down_position)

	# tear down
	_free_generated_content(generated_dungeon)


func test_progression_regeneration_is_deterministic():
	# arrange
	var first_dungeon = dungeon_generator.generate_dungeon(Vector2i(40, 23), 3, 4711)

	# act
	var revisited_dungeon = dungeon_generator.generate_dungeon(Vector2i(40, 23), 3, 4711)

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


func _free_generated_content(generated_dungeon: Dungeon) -> void:
	for item in generated_dungeon.items:
		item.free()
	for enemy in generated_dungeon.enemies:
		enemy.free()


func test_place_enemies():
	# arrange
	var root_node = Branch.new(Vector2i.ZERO, Vector2i(20, 20))
	var paths: Array[Dictionary] = []
	root_node.split(3, paths)
	
	# act
	var enemies = dungeon_generator._place_enemies(root_node)
	
	# assert
	assert_true(enemies.size() > 0, "Enemies should be placed in the dungeon")

	# tear down
	for enemy in enemies:
		enemy.free()


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
