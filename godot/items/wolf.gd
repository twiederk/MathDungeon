class_name Wolf
extends Item

@export var damage: int


func execute() -> void:
	PlayerStats.weapon_damage += 1
