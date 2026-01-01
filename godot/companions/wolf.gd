class_name Wolf
extends Companion

@export var damage: int


func execute() -> void:
	PlayerStats.weapon_damage += damage
