extends Node


signal health_changed


var max_hit_points: int = 5


var hit_points: int = 5:
	set(value):
		hit_points = value
		if hit_points > 0:
			SaveManager.save_game()
		health_changed.emit()


var weapon_damage: int = 1:
	set(value):
		weapon_damage = value
		SaveManager.save_game()


var armor: int = 0:
	set(value):
		armor = value
		SaveManager.save_game()


func reset() -> void:
	hit_points = 5
	weapon_damage = 1
	armor = 0


func hurt(damage: int) -> int:
	hit_points -= min(1, damage - armor)
	return hit_points
