extends Node


var damage: int = 1:
	set(value):
		damage = value
		SaveManager.save_game()


var hit_points: int = 5:
	set(value):
		hit_points = value
		SaveManager.save_game()
