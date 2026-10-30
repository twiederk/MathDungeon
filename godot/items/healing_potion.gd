class_name HealingPotion
extends Item

@export var good_resource: GoodResource


func execute() -> void:
	if CharacterManager.current.inventory.add_potion(good_resource):
		Sound.play(Sound.pickup_potion)
		queue_free()
