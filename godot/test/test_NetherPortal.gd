extends GutTest


const NETHER_SCENE := preload("res://classic/nether.tscn")


func test_nether_portal_targets_the_overworld():
	# arrange
	var nether_scene = autofree(NETHER_SCENE.instantiate())
	var portal = nether_scene.get_node("Locations/NetherPortal")
	
	# assert
	assert_eq(portal.dungeon_path, "res://classic/overworld.tscn")
