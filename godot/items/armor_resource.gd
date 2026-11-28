class_name ArmorResource
extends ItemResource

@export var armor: int = 0


func get_level() -> int:
	return armor * 2
