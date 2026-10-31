extends GutTest


func after_each():
	GameSession.overworld_path = GameSession.DEFAULT_OVERWORLD_PATH


func test_target_path_uses_the_exported_dungeon_path():
	# arrange
	var portal = autofree(NetherPortal.new())
	portal.dungeon_path = "res://classic/nether.tscn"
	
	# act
	var target_path = portal.get_target_path()
	
	# assert
	assert_eq(target_path, "res://classic/nether.tscn")


func test_target_path_falls_back_to_the_session_overworld_path():
	# arrange
	var portal = autofree(NetherPortal.new())
	portal.dungeon_path = ""
	GameSession.overworld_path = "res://procedural/proc_gen_world.tscn"
	
	# act
	var target_path = portal.get_target_path()
	
	# assert
	assert_eq(target_path, "res://procedural/proc_gen_world.tscn")
