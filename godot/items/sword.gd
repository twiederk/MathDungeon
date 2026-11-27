class_name Sword
extends ItemScene

@export var weapon_resource: WeaponResource


func get_item_resource() -> WeaponResource:
	return weapon_resource


func get_level() -> int:
	return weapon_resource.get_level()


func execute() -> void:
	CharacterManager.current.inventory.equip_weapon(weapon_resource)
	Sound.play(Sound.pickup_sword)
	queue_free()
