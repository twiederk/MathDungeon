class_name Sword
extends Item

@export var damage: int


func execute() -> void:
	PlayerStats.weapon_damage = damage
