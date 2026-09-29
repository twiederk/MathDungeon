class_name PortraitCatalog
extends Resource

@export var portraits: Array[Portrait] = []


func get_portrait(portrait_id: String) -> Portrait:
	for portrait in portraits:
		if portrait.id == portrait_id:
			return portrait
	return null


func get_texture(portrait_id: String) -> Texture2D:
	var portrait: Portrait = get_portrait(portrait_id)
	if portrait == null:
		return null
	return portrait.texture
