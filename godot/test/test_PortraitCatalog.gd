extends GutTest

const PORTRAIT_CATALOG: PortraitCatalog = preload("res://characters/portrait_catalog.tres")


func test_portrait_id_resolves_to_portrait_and_texture():
	# arrange
	var portrait_id: String = "000"

	# act
	var portrait: Portrait = PORTRAIT_CATALOG.get_portrait(portrait_id)

	# assert
	assert_eq(portrait.id, portrait_id, "Should return proper portrait")
	assert_not_null(portrait.texture, "Should contain portrait as texture")


func test_unknown_id_does_not_resolve():
	# arrange
	var unknown_id: String = "unknown"

	# act
	var portrait: Portrait = PORTRAIT_CATALOG.get_portrait(unknown_id)

	# assert
	assert_null(portrait, "Should return null, when no portrait is found")
