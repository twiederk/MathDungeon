class_name WeaponResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var damage: int = 0
@export var icon_atlas: AtlasTexture


func get_level() -> int:
	return damage * 2 - 2
