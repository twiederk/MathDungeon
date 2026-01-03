class_name Wolf
extends Companion

@export var damage: int

var damage_applied: bool = false


func execute() -> void:
	if not damage_applied:
		Sound.play(Sound.dog_bark)
		damage_applied = true
		PlayerStats.add_companion(str(get_path()), damage)


func set_damage_applied() -> void:
	damage_applied = true
