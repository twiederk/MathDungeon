class_name EnemyGenerator

const SPAWN_CHANCE_ENEMY_EASY = 80
const SPAWN_CHANCE_ENEMY_MEDIUM = 70

# Enemies
const SKELETON_SCENE = preload("res://procedural/enemies/skeleton.tscn")
const SKELETON_SWORDLESS_SCENE = preload("res://procedural/enemies/skeleton_swordless.tscn")
const SLIME_SCENE = preload("res://procedural/enemies/slime.tscn")


func generate_enemies(root_node: Branch)  -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var enemies_easy = [SLIME_SCENE, SKELETON_SWORDLESS_SCENE]
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
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.position = room.get_center()
		enemies.append(enemy)

	for room_index in range(half_number_of_rooms + 1, number_of_rooms - 1):
		if randi_range(0, 100) > SPAWN_CHANCE_ENEMY_MEDIUM:
			continue
		var room = rooms[room_index]
		var enemy_scene = enemies_medium.pick_random()
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.position = room.get_center()
		enemies.append(enemy)

	return enemies
