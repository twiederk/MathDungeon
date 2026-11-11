class_name WorldLevel
extends Node2D


const NAME_ENTRY_DIALOG_PATH := "res://gui/name_entry_dialog.tscn"
const HIGHSCORE_GUI_PATH := "res://gui/highscore_gui.tscn"

var loot_droper: LootDropper = LootDropper.new()

@onready var enemies_root: Node = $Enemies
@onready var items_root: Node = $Items
@onready var companions_root = $Companions
@onready var player: Player = $Player
@onready var map_borders = $MapBorders
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var nether_portal: NetherPortal = get_node_or_null("Locations/NetherPortal")
@onready var cave_entrance: CaveEntrance = get_node_or_null("Locations/CaveEntrance")

@onready var quiz: Control = $UI/QuizDialog
@onready var player_stats_sheet: StatsSheet = $UI/PlayerStatsSheet
@onready var countdown_timer_widget: CountdownTimerWidget = $UI/CountdownTimerWidget


func _ready() -> void:
	_apply_start_position()
	_register_return_path()
	_setup_signals()
	_setup_locations()
	_setup_limits_and_borders()
	_setup_character_stats()
	CompanionSetup.new(companions_root, player).setup()
	_on_simulation_running_changed(GameSession.is_simulation_running())
	countdown_timer_widget.visible = GameSession.is_timed_run()
	GameSession.run_time_expired.connect(_on_run_time_expired)


func _register_return_path() -> void:
	if scene_file_path.is_empty():
		return
	if nether_portal == null or nether_portal.dungeon_path.is_empty():
		return
	GameSession.set_overworld_path(scene_file_path)


func _apply_start_position() -> void:
	player.global_position = get_start_position()


func get_start_position() -> Vector2:
	if GameSession.spawns_at_nether_portal():
		if nether_portal:
			return nether_portal.get_spawn_position()
	if GameSession.spawns_at_cave_entrance():
		if cave_entrance:
			return cave_entrance.get_spawn_position()
	return player.global_position


func _setup_locations() -> void:
	AchievementManager.clear_locations()
	AchievementManager.register_locations(enemies_root.find_children("", "Enemy", true, false))


func _setup_signals() -> void:
	GameSession.simulation_running_changed.connect(_on_simulation_running_changed)

	for child in enemies_root.get_children():
		if child.has_signal("encountered"):
			child.encountered.connect(_on_enemy_encountered)
		if child.has_signal("defeated"):
			child.defeated.connect(_on_enemy_defeated)

	for child in items_root.get_children():
		if child.has_signal("item_picked_up"):
			_register_item(child as Item)

	for child in companions_root.get_children():
		if child.has_signal("companion_picked_up"):
			child.companion_picked_up.connect(_on_companion_picked_up)


func _on_simulation_running_changed(running: bool) -> void:
	var mode := Node.PROCESS_MODE_INHERIT
	if not running:
		mode = Node.PROCESS_MODE_DISABLED
	player.set_deferred("process_mode", mode)
	enemies_root.set_deferred("process_mode", mode)
	companions_root.set_deferred("process_mode", mode)


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
	var character := CharacterManager.current
	character.hit_points_changed.connect(_on_player_stats_changed)
	character.damage_changed.connect(_on_player_stats_changed)
	character.armor_changed.connect(_on_player_stats_changed)
	player_stats_sheet.update_stats(character.hit_points, character.max_hit_points, character.get_damage(), character.get_armor())


func _on_enemy_encountered(enemy: StaticBody2D, attack_type: Enemy.AttackType) -> void:
	quiz.open_for(enemy, attack_type)


func _on_enemy_defeated(enemy: Enemy) -> void:
	for item in loot_droper.drop_items(enemy, items_root):
		_register_item(item)
	if enemy.is_in_group("villagers"):
		_enrage_iron_golems(enemy.global_position)


func _enrage_iron_golems(villager_position: Vector2) -> void:
	for child in enemies_root.get_children():
		if child.has_method("on_villager_defeated"):
			child.on_villager_defeated(villager_position, player)


func _register_item(item: Item) -> void:
	if not item.item_picked_up.is_connected(_on_item_picked_up):
		item.item_picked_up.connect(_on_item_picked_up)


func _on_item_picked_up(item: Item) -> void:
	item.execute()


func _on_companion_picked_up(companion: Companion) -> void:
	CharacterManager.current.add_companion(String(companion.get_script().get_global_name()))
	companion.execute()
	if player:
		companion.start_following(player)


func _on_player_stats_changed() -> void:
	var character := CharacterManager.current
	player_stats_sheet.update_stats(character.hit_points, character.max_hit_points, character.get_damage(), character.get_armor())


func _on_run_time_expired() -> void:
	GameSession.display_state = GameSession.DisplayState.NONE
	GameSession.stop_run()
	get_tree().change_scene_to_file(_resolve_run_end_scene())


func _resolve_run_end_scene() -> String:
	if HighscoreManager.is_highscore(GameSession.score):
		return NAME_ENTRY_DIALOG_PATH
	return HIGHSCORE_GUI_PATH
