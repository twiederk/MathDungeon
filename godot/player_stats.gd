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


func reset() -> void:
	hit_points = 5
	damage = 1
