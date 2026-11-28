class_name EyeOfEnder
extends ItemScene

@export var good_resource: GoodResource


func get_item_resource() -> GoodResource:
	return good_resource


func get_level() -> int:
	return good_resource.get_level()


func execute() -> void:
	CharacterManager.current.equip_good(good_resource)
	Sound.play(Sound.victory)
	queue_free()
