extends GutTest


func after_each():
	GameSession.spawn_point = GameSession.SpawnPoint.START


func _build_level(scene_path: String, portal: NetherPortal) -> WorldLevel:
	var level = autofree(WorldLevel.new())
	level.scene_file_path = scene_path
	level.nether_portal = portal
	return level


func test_classic_world_scene_titles(parameters = use_parameters([
	["res://classic/overworld.tscn", "Oberwelt"],
	["res://classic/nether.tscn", "Nether"],
	["res://classic/end.tscn", "Das Ende"],
	["res://classic/ancient_city.tscn", "Antike Stadt"]
])):
	# arrange
	var scene = load(parameters[0]) as PackedScene
	var level = autofree(scene.instantiate())

	# act
	var title = level._get_world_title()

	# assert
	assert_eq(title, parameters[1])


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
