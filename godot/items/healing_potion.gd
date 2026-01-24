class_name HealingPotion
extends Item


func execute() -> void:
	PlayerStats.hit_points = 5
	Sound.play(Sound.pickup_potion)
