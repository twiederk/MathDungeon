class_name HealingPotion
extends Item


func execute() -> void:
	if CharacterManager.current.inventory.add_potion():
		Sound.play(Sound.pickup_potion)
		queue_free()
	else:
		Sound.play(Sound.pickup_potion, 0.6)
