class_name EnemyGenerator

const SPAWN_CHANCE_ENEMY_EASY = 80
const SPAWN_CHANCE_ENEMY_MEDIUM = 70

# Enemies
const ZOMBIE_BABY_SCENE = preload("res://enemies/zombie_baby.tscn")
const ZOMBIE_SCENE = preload("res://enemies/zombie.tscn")
const DROWN_SCENE = preload("res://enemies/drown.tscn")
const CREEPER_SCENE = preload("res://enemies/creeper.tscn")
const SPIDER_SCENE = preload("res://enemies/spider.tscn")
const SHOOTING_SKELETON_SCENE = preload("res://enemies/shooting_skeleton.tscn")
const PIGLIN_SCENE = preload("res://enemies/piglin.tscn")
const PIGLIN_ZOMBIE_SCENE = preload("res://enemies/piglin_zombie.tscn")
const ENDERMAN_SCENE = preload("res://enemies/enderman.tscn")


func generate_enemies(root_node: Branch)  -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var enemies_easy = [ZOMBIE_BABY_SCENE, ZOMBIE_SCENE, DROWN_SCENE]
	var enemies_medium = [CREEPER_SCENE, SPIDER_SCENE, SHOOTING_SKELETON_SCENE, PIGLIN_ZOMBIE_SCENE]

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

	var last_room = rooms[-1]
	var enderman = ENDERMAN_SCENE.instantiate() as Enemy
	enderman.position = last_room.get_center()
	enemies.append(enderman)
	
	return enemies
