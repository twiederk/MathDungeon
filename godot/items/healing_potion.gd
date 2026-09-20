class_name HealingPotion
extends Item


func execute() -> void:
	if CharacterManager.current.needs_healing():
		CharacterManager.current.hit_points = CharacterManager.current.max_hit_points
		Sound.play(Sound.pickup_potion)
		queue_free()
