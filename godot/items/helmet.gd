class_name Helmet
extends Item

@export var armor_resource: ArmorResource


func execute() -> void:
	CharacterManager.current.inventory.equip_armor(armor_resource)
	Sound.play(Sound.pickup_helmet)
	queue_free()
