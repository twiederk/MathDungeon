class_name Main
extends Node2D

@onready var enemies_root: Node = $Enemies
@onready var items_root: Node = $Items
@onready var companions_root = $Companions

@onready var quiz: Control = $UI/QuizDialog
@onready var player_stats_sheet: StatsSheet = $UI/PlayerStatsSheet


func _init() ->  void:
	randomize()


func _ready() -> void:
	for child in enemies_root.get_children():
		if child.has_signal("encountered"):
			child.encountered.connect(_on_enemy_encountered)

	for child in items_root.get_children():
		if child.has_signal("item_picked_up"):
			child.item_picked_up.connect(_on_item_picked_up)

	for child in companions_root.get_children():
		if child.has_signal("companion_picked_up"):
			child.companion_picked_up.connect(_on_companion_picked_up)

	PlayerStats.health_changed.connect(_on_player_stats_changed)
	PlayerStats.weapon_damage_changed.connect(_on_player_stats_changed)
	PlayerStats.armor_changed.connect(_on_player_stats_changed)
	player_stats_sheet.update_stats(PlayerStats.hit_points, PlayerStats.max_hit_points, PlayerStats.weapon_damage, PlayerStats.armor)


func _on_enemy_encountered(enemy: Area2D) -> void:
	quiz.open_for(enemy)


func _on_item_picked_up(item: Item) -> void:
	item.execute()
	item.queue_free()


func _on_companion_picked_up(companion: Companion) -> void:
	companion.execute()
	companion.queue_free()


func _on_player_stats_changed() -> void:
	player_stats_sheet.update_stats(PlayerStats.hit_points, PlayerStats.max_hit_points, PlayerStats.weapon_damage, PlayerStats.armor)
