class_name Sword
extends Item

@export var weapon_resource: WeaponResource


func execute() -> void:
	CharacterManager.current.inventory.equip_weapon(weapon_resource)
	Sound.play(Sound.pickup_sword)
	queue_free()
