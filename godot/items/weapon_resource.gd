class_name WeaponResource
extends ItemResource

@export var damage: int = 0


func get_level() -> int:
	return damage * 2 - 2
