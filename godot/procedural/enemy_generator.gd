class_name EnemyGenerator
extends Generator

const SPAWN_CHANCE_ENEMY_EASY = 80
const SPAWN_CHANCE_ENEMY_MEDIUM = 70
const SPAWN_CHANCE_ENEMY_HARD = 70

# Enemies
const SKELETON_SCENE = preload("res://procedural/enemies/skeleton.tscn")
const SKELETON_SWORDLESS_SCENE = preload("res://procedural/enemies/skeleton_swordless.tscn")
const SLIME_SCENE = preload("res://procedural/enemies/slime.tscn")
const SLIME_GREEN_SCENE = preload("res://procedural/enemies/slime_green.tscn")
const SLIME_YELLOW_SCENE = preload("res://procedural/enemies/slime_yellow.tscn")
const SLIME_MAGENTA_SCENE = preload("res://procedural/enemies/slime_magenta.tscn")
const SLIME_CYAN_SCENE = preload("res://procedural/enemies/slime_cyan.tscn")
const SLIME_RED_SCENE = preload("res://procedural/enemies/slime_red.tscn")
const LEVEL_ENEMY_POOLS := [
	{"easy": [SLIME_YELLOW_SCENE], "medium": [SLIME_YELLOW_SCENE, SLIME_CYAN_SCENE, SKELETON_SWORDLESS_SCENE]},
	{"easy": [SLIME_CYAN_SCENE], "medium": [SLIME_CYAN_SCENE, SLIME_MAGENTA_SCENE, SKELETON_SWORDLESS_SCENE]},
	{"easy": [SLIME_MAGENTA_SCENE], "medium": [SLIME_MAGENTA_SCENE, SLIME_GREEN_SCENE, SKELETON_SWORDLESS_SCENE]},
	{"easy": [SLIME_GREEN_SCENE, SKELETON_SWORDLESS_SCENE], "medium": [SLIME_GREEN_SCENE, SLIME_SCENE, SKELETON_SCENE]},
	{"easy": [SLIME_SCENE, SKELETON_SWORDLESS_SCENE], "medium": [SLIME_SCENE, SLIME_RED_SCENE, SKELETON_SCENE]},
	{"easy": [SLIME_RED_SCENE, SKELETON_SWORDLESS_SCENE], "medium": [SLIME_RED_SCENE, SKELETON_SCENE]},
]


static func get_enemy_pools(level_index: int) -> Dictionary:
	return LEVEL_ENEMY_POOLS[mini(level_index, LEVEL_ENEMY_POOLS.size()) - 1]


func generate_enemies(root_node: Branch, easy_enemies: Array[PackedScene], medium_enemies: Array[PackedScene], hard_enemies: Array[PackedScene]) -> Array[Enemy]:
	var enemies: Array[Enemy] = []

	var rooms = root_node.get_leaves()
	var number_of_rooms = rooms.size()

	for room_index in range(1, number_of_rooms - 1):
		var room_progress: float = float(room_index) / number_of_rooms
		var tier := _get_room_tier(room_progress)
		var enemy_pool: Array[PackedScene] = []
		var spawn_chance: int = 0
		match tier:
			Generator.Tier.EASY:
				enemy_pool = easy_enemies
				spawn_chance = SPAWN_CHANCE_ENEMY_EASY
			Generator.Tier.MEDIUM:
				enemy_pool = medium_enemies
				spawn_chance = SPAWN_CHANCE_ENEMY_MEDIUM
			Generator.Tier.HARD:
				enemy_pool = hard_enemies
				spawn_chance = SPAWN_CHANCE_ENEMY_HARD

		if enemy_pool.is_empty() or randi_range(0, 100) > spawn_chance:
			continue
		var room = rooms[room_index]
		var enemy_scene = enemy_pool.pick_random()
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
