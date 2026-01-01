extends Node


signal health_changed
signal weapon_damage_changed
signal armor_changed


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
		weapon_damage_changed.emit()


var armor: int = 0:
	set(value):
		armor = value
		SaveManager.save_game()
		armor_changed.emit()


func reset() -> void:
	hit_points = 5
	weapon_damage = 1
	armor = 0


func hurt(damage: int) -> int:
	hit_points -= max(1, damage - armor)
	return hit_points
