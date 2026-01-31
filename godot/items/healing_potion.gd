class_name HealingPotion
extends Item


func execute() -> void:
	if PlayerStats.needs_healing():
		PlayerStats.hit_points = PlayerStats.max_hit_points
		Sound.play(Sound.pickup_potion)
		queue_free()
