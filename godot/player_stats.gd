extends Node


signal health_changed
signal weapon_damage_changed
signal armor_changed
signal score_changed


var max_hit_points: int = 5
var has_lighter: bool = false
var companion_paths: Array[String] = []
var current_score: int = 0:
	set(value):
		current_score = value
		score_changed.emit()


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
	current_score = 0
	has_lighter = false
	companion_paths.clear()


func add_score(score: int) -> void:
	current_score += score


func add_companion(companion_path: String) -> void:
	if companion_path not in companion_paths:
		companion_paths.append(companion_path)
		weapon_damage_changed.emit()
		SaveManager.save_game()


func get_total_damage() -> int:
	var total = weapon_damage
	for companion_path in companion_paths:
		var companion = get_node_or_null(companion_path)
		if companion and "damage" in companion:
			total += companion.damage
	return total


func hurt(damage: int) -> int:
	hit_points -= max(1, damage - armor)
	return hit_points
