class_name HealingPotion
extends ItemScene

@export var good_resource: GoodResource


func get_item_resource() -> GoodResource:
	return good_resource


func get_level() -> int:
	return good_resource.get_level()


func execute() -> void:
	if CharacterManager.current.inventory.add_potion(good_resource):
		Sound.play(Sound.pickup_potion)
		queue_free()
