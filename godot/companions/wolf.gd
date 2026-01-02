class_name Wolf
extends Companion

@export var damage: int

var damage_applied: bool = false


func execute() -> void:
	if not damage_applied:
		Sound.play(Sound.dog_bark)
		PlayerStats.add_companion_damage(damage)
		damage_applied = true
