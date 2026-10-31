extends GutTest


func after_each():
	GameSession.overworld_path = GameSession.DEFAULT_OVERWORLD_PATH


func _build_level(scene_path: String, portal: NetherPortal) -> WorldLevel:
	var level = autofree(WorldLevel.new())
	level.scene_file_path = scene_path
	level.nether_portal = portal
	return level


func test_register_return_path_stores_the_scene_path():
	# arrange
	var portal = autofree(NetherPortal.new())
	portal.dungeon_path = "res://classic/nether.tscn"
	var level = _build_level("res://procedural/proc_gen_world.tscn", portal)
	
	# act
	level._register_return_path()
	
	# assert
	assert_eq(GameSession.overworld_path, "res://procedural/proc_gen_world.tscn")


func test_register_return_path_ignores_levels_without_a_nether_portal():
	# arrange
	var level = _build_level("res://classic/nether.tscn", null)
	
	# act
	level._register_return_path()
	
	# assert
	assert_eq(GameSession.overworld_path, GameSession.DEFAULT_OVERWORLD_PATH)


func test_register_return_path_ignores_portals_without_a_dungeon_path():
	# arrange
	var portal = autofree(NetherPortal.new())
	portal.dungeon_path = ""
	var level = _build_level("res://classic/nether.tscn", portal)
	
	# act
	level._register_return_path()
	
	# assert
	assert_eq(GameSession.overworld_path, GameSession.DEFAULT_OVERWORLD_PATH)
