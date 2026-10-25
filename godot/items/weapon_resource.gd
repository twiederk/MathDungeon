class_name WeaponResource
extends Resource

const ICON_GRID_SIZE: int = 16

@export var id: String = ""
@export var name: String = ""
@export var damage: int = 0
@export var icon_texture: Texture2D
@export var icon_frame: int = 0


func get_icon() -> Texture2D:
	if icon_texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = icon_texture
	var cell := icon_texture.get_size() / Vector2(ICON_GRID_SIZE, ICON_GRID_SIZE)
	var col := icon_frame % ICON_GRID_SIZE
	@warning_ignore("integer_division")
	var row := icon_frame / ICON_GRID_SIZE
	atlas.region = Rect2(col * cell.x, row * cell.y, cell.x, cell.y)
	return atlas
