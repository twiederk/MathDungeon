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


func test_place_enemies():
	# arrange
	var root_node = Branch.new(Vector2i.ZERO, Vector2i(20, 20))
	var paths: Array[Dictionary] = []
	root_node.split(3, paths)
	
	# act
	var enemies = dungeon_generator._place_enemies(root_node)
	
	# assert
	assert_true(enemies.size() > 0, "Enemies should be placed in the dungeon")
