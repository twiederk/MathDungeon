class_name Wolf
extends Companion

@export var damage: int

var damage_applied: bool = false


func execute() -> void:
	if not damage_applied:
		PlayerStats.weapon_damage += damage
		damage_applied = true
