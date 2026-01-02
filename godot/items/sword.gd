class_name Sword
extends Item

@export var damage: int


func execute() -> void:
	if damage > PlayerStats.weapon_damage:
		PlayerStats.weapon_damage = damage
	Sound.play(Sound.pickup_sword)
