extends GutTest


func after_each():
	GameSession.spawn_point = GameSession.SpawnPoint.START


func _build_level(scene_path: String, portal: NetherPortal) -> WorldLevel:
	var level = autofree(WorldLevel.new())
	level.scene_file_path = scene_path
	level.nether_portal = portal
	return level


func test_get_start_position_uses_the_nether_portal_marker():
	# arrange
	var portal = autofree(NetherPortal.new())
	var spawn_marker = autofree(Marker2D.new())
	spawn_marker.position = Vector2(12, 34)
	portal.spawn_point = spawn_marker
	var level = _build_level("res://procedural/proc_gen_world.tscn", portal)
	GameSession.spawn_point = GameSession.SpawnPoint.NETHER_PORTAL

	# act
	var start_position = level.get_start_position()

	# assert
	assert_eq(start_position, spawn_marker.global_position)
