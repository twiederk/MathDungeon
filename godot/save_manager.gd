extends Node

const TEST_PATH: String = "res://save.txt"
const PROD_PATH: String = "user://math_dungeon_save.save"

var save_path: String = PROD_PATH


func save_game():
	var data = {
		"player" = {
			"damage": PlayerStats.damage,
			"hit_points": PlayerStats.hit_points,
			"armor": PlayerStats.armor,
		}
	}	
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	var data_string = JSON.stringify(data)
	save_file.store_string(data_string)
	save_file.close()


func is_save_game_available():
	return FileAccess.file_exists(save_path)


func load_game():
	var load_file = FileAccess.open(save_path, FileAccess.READ)
	var data =  JSON.parse_string(load_file.get_line())
	PlayerStats.damage = data["player"]["damage"]
	PlayerStats.hit_points = data["player"]["hit_points"]
	PlayerStats.armor = data["player"]["armor"]
	load_file.close()
