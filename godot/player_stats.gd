extends Node


signal health_changed


var damage: int = 1:
	set(value):
		damage = value
		SaveManager.save_game()


var hit_points: int = 5:
	set(value):
		hit_points = value
		if hit_points > 0:
			SaveManager.save_game()
		health_changed.emit()


var max_hit_points: int = 5
var armor: int = 0


func reset() -> void:
	hit_points = 5
	damage = 1
	armor = 0


func hurt(damage: int) -> int:
	hit_points -= min(1, damage - armor)
	return hit_points
	
