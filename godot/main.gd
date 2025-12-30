class_name Main
extends Node2D

@onready var enemies_root: Node = $Enemies
@onready var items_root: Node = $Items
@onready var quiz: Control = $UI/QuizDialog
@onready var health_meter_widget: HealthMeterWidget = $UI/HealthMeterWidget


func _init() ->  void:
	randomize()


func _ready() -> void:
	for child in enemies_root.get_children():
		if child.has_signal("encountered"):
			child.encountered.connect(_on_enemy_encountered)

	for child in items_root.get_children():
		if child.has_signal("item_picked_up"):
			child.item_picked_up.connect(_on_item_picked_up)
			
	PlayerStats.health_changed.connect(_on_player_health_changed)
	health_meter_widget.update_health_ui(PlayerStats.hit_points)
	health_meter_widget.update_max_health_ui(PlayerStats.hit_points)


func _on_enemy_encountered(enemy: Area2D) -> void:
	quiz.open_for(enemy)


func _on_item_picked_up(item: Item) -> void:
	item.execute()
	item.queue_free()


func _on_player_health_changed() -> void:
	health_meter_widget.update_health_ui(PlayerStats.hit_points)
