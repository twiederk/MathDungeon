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
const ENEMY_CATALOG := [
	{"scene": SLIME_YELLOW_SCENE, "stats": preload("res://procedural/enemies/slime_yellow_stats.tres")},
	{"scene": SLIME_CYAN_SCENE, "stats": preload("res://procedural/enemies/slime_cyan_stats.tres")},
	{"scene": SLIME_MAGENTA_SCENE, "stats": preload("res://procedural/enemies/slime_magenta_stats.tres")},
	{"scene": SKELETON_SWORDLESS_SCENE, "stats": preload("res://procedural/enemies/skeleton_swordless_stats.tres")},
	{"scene": SLIME_GREEN_SCENE, "stats": preload("res://procedural/enemies/slime_green_stats.tres")},
	{"scene": SLIME_SCENE, "stats": preload("res://procedural/enemies/slime_stats.tres")},
	{"scene": SKELETON_SCENE, "stats": preload("res://procedural/enemies/skeleton_stats.tres")},
	{"scene": SLIME_RED_SCENE, "stats": preload("res://procedural/enemies/slime_red_stats.tres")},
]


func generate_enemies(root_node: Branch, dungeon_level: int) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	var easy_enemies := _get_enemy_pool(dungeon_level, Generator.Tier.EASY)
	var medium_enemies := _get_enemy_pool(dungeon_level, Generator.Tier.MEDIUM)
	var hard_enemies := _get_enemy_pool(dungeon_level, Generator.Tier.HARD)

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


func _get_enemy_pool(dungeon_level: int, tier: int) -> Array[PackedScene]:
	var max_level := _get_max_enemy_level()
	var effective_level := clampi(dungeon_level, 1, max_level)
	var eligible_levels := _get_eligible_content_levels(effective_level, tier)
	var enemy_pool: Array[PackedScene] = []
	for definition in ENEMY_CATALOG:
		var stats: EnemyStats = definition.stats
		if eligible_levels.has(stats.level):
			var enemy_scene: PackedScene = definition.scene
			enemy_pool.append(enemy_scene)
	return enemy_pool


func _get_max_enemy_level() -> int:
	var max_level := 1
	for definition in ENEMY_CATALOG:
		var stats: EnemyStats = definition.stats
		max_level = maxi(max_level, stats.level)
	return max_level


func _find_spawn_position(room: Room) -> Variant:
	var entrances := room.get_entrances()
	if not entrances.is_empty():
		return entrances[0]
	return room.get_center()
