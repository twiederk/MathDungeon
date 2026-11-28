extends GutTest

const EYE_OF_ENDER_SCENE: PackedScene = preload("res://items/eye_of_ender.tscn")


func test_base_item_scene_returns_no_resource():
	# arrange
	var item_scene := ItemScene.new()

	# act
	var actual_resource: ItemResource = item_scene.get_item_resource()

	# assert
	assert_null(actual_resource)
	item_scene.free()


func test_base_item_scene_returns_invalid_level():
	# arrange
	var item_scene := ItemScene.new()

	# act
	var actual_level = item_scene.get_level()

	# assert
	assert_eq(actual_level, ItemResource.INVALID_LEVEL)
	item_scene.free()


func test_player_body_emits_pickup_signal():
	# arrange
	var item_scene := ItemScene.new()
	var player := Node.new()
	player.name = "Player"
	watch_signals(item_scene)

	# act
	item_scene._on_body_entered(player)

	# assert
	assert_signal_emitted_with_parameters(item_scene, "item_picked_up", [item_scene])
	item_scene.free()
	player.free()


func test_eye_of_ender_returns_assigned_resource():
	# arrange
	var eye_of_ender := EYE_OF_ENDER_SCENE.instantiate() as EyeOfEnder
	var expected_resource: GoodResource = eye_of_ender.good_resource

	# act
	var actual_resource: GoodResource = eye_of_ender.get_item_resource()

	# assert
	assert_eq(actual_resource, expected_resource)
	eye_of_ender.free()


func test_eye_of_ender_delegates_level_to_resource():
	# arrange
	var eye_of_ender := EYE_OF_ENDER_SCENE.instantiate() as EyeOfEnder

	# act
	var actual_level = eye_of_ender.get_level()

	# assert
	assert_eq(actual_level, 1)
	eye_of_ender.free()