class_name Main
extends Node2D

@onready var enemies_root: Node = $Enemies
@onready var items_root: Node = $Items
@onready var companions_root = $Companions
@onready var player: Player = $Player
@onready var map_borders = $MapBorders
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

@onready var quiz: Control = $UI/QuizDialog
@onready var player_stats_sheet: StatsSheet = $UI/PlayerStatsSheet


func _ready() -> void:
	_setup_signals()
	_setup_limits_and_borders()
	_setup_character_stats()
	_setup_companions()	


func _setup_signals() -> void:
	for child in enemies_root.get_children():
		if child.has_signal("encountered"):
			child.encountered.connect(_on_enemy_encountered)

	for child in items_root.get_children():
		if child.has_signal("item_picked_up"):
			child.item_picked_up.connect(_on_item_picked_up)

	for child in companions_root.get_children():
		if child.has_signal("companion_picked_up"):
			child.companion_picked_up.connect(_on_companion_picked_up)


func _setup_limits_and_borders() -> void:
	var tile_map_used_rect = tile_map_layer.get_used_rect()
	var tile_size = tile_map_layer.tile_set.tile_size
	var north_limit = tile_map_used_rect.position.y * tile_size.y
	var south_limit = (tile_map_used_rect.position.y + tile_map_used_rect.size.y) * tile_size.y
	var west_limit = tile_map_used_rect.position.x * tile_size.x
	var east_limit = (tile_map_used_rect.position.x + tile_map_used_rect.size.x) * tile_size.x
	
	map_borders.set_borders(north_limit, south_limit, west_limit, east_limit)
	player.set_camera_limits(north_limit, south_limit, west_limit, east_limit)


func _setup_character_stats() -> void:
	PlayerStats.health_changed.connect(_on_player_stats_changed)
	PlayerStats.weapon_damage_changed.connect(_on_player_stats_changed)
	PlayerStats.armor_changed.connect(_on_player_stats_changed)
	player_stats_sheet.update_stats(PlayerStats.hit_points, PlayerStats.max_hit_points, PlayerStats.get_total_damage(), PlayerStats.armor)


func _on_enemy_encountered(enemy: StaticBody2D) -> void:
	quiz.open_for(enemy)


func _on_item_picked_up(item: Item) -> void:
	item.execute()
	item.queue_free()


func _on_companion_picked_up(companion: Companion) -> void:
	companion.execute()
	if player:
		companion.start_following(player)


func _on_player_stats_changed() -> void:
	player_stats_sheet.update_stats(PlayerStats.hit_points, PlayerStats.max_hit_points, PlayerStats.get_total_damage(), PlayerStats.armor)


func _setup_companions() -> void:
	for i in range(PlayerStats.companion_paths.size()):
		var companion_path = PlayerStats.companion_paths[i]
		var companion = get_node_or_null(companion_path)
		
		if companion and companion.has_method("start_following"):
			var offset = Vector2(60.0 + (i * 40.0), 0.0)
			companion.global_position = player.global_position + offset
			companion.start_following(player)
			if companion.has_method("set_damage_applied"):
				companion.set_damage_applied()
