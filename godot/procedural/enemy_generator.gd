class_name EnemyGenerator

const SPAWN_CHANCE_ENEMY_EASY = 80
const SPAWN_CHANCE_ENEMY_MEDIUM = 70

# Enemies
const SKELETON_SCENE = preload("res://procedural/enemies/skeleton.tscn")
const SKELETON_SWORDLESS_SCENE = preload("res://procedural/enemies/skeleton_swordless.tscn")
const SLIME_SCENE = preload("res://procedural/enemies/slime.tscn")
const SLIME_GREEN_SCENE = preload("res://procedural/enemies/slime_green.tscn")
const SLIME_YELLOW_SCENE = preload("res://procedural/enemies/slime_yellow.tscn")
const SLIME_MAGENTA_SCENE = preload("res://procedural/enemies/slime_magenta.tscn")
const SLIME_CYAN_SCENE = preload("res://procedural/enemies/slime_cyan.tscn")
const SLIME_RED_SCENE = preload("res://procedural/enemies/slime_red.tscn")


func generate_enemies(root_node: Branch) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var enemies_easy = [
		SLIME_SCENE, SLIME_GREEN_SCENE, SLIME_YELLOW_SCENE,
		SLIME_MAGENTA_SCENE, SLIME_CYAN_SCENE, SLIME_RED_SCENE,
		SKELETON_SWORDLESS_SCENE,
	]
	var enemies_medium = [SKELETON_SCENE]

	var rooms = root_node.get_leaves()
	var number_of_rooms = rooms.size()
	@warning_ignore("integer_division")
	var half_number_of_rooms: int = number_of_rooms / 2

	for room_index in range(1, half_number_of_rooms + 1):
		if randi_range(0, 100) > SPAWN_CHANCE_ENEMY_EASY:
			continue
		var room = rooms[room_index]
		var enemy_scene = enemies_easy.pick_random()
		var spawn_position = _find_spawn_position(room)
		if spawn_position == null:
			continue
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.position = spawn_position
		enemies.append(enemy)

	for room_index in range(half_number_of_rooms + 1, number_of_rooms - 1):
		if randi_range(0, 100) > SPAWN_CHANCE_ENEMY_MEDIUM:
			continue
		var room = rooms[room_index]
		var enemy_scene = enemies_medium.pick_random()
		var spawn_position = _find_spawn_position(room)
		if spawn_position == null:
			continue
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.position = spawn_position
		enemies.append(enemy)

	return enemies


func _find_spawn_position(room: Room) -> Variant:
	var entrances := room.get_entrances()
	if not entrances.is_empty():
		return entrances[0]
	return room.get_center()
