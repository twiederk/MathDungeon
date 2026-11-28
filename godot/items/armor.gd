class_name Armor
extends ItemScene

@export var armor_resource: ArmorResource


func get_item_resource() -> ArmorResource:
	return armor_resource


func get_level() -> int:
	return armor_resource.get_level()


func execute() -> void:
	CharacterManager.current.inventory.equip_armor(armor_resource)
	Sound.play(Sound.pickup_helmet)
	queue_free()
