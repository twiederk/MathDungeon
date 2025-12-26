class_name Main
extends Node2D

@onready var quiz: Control = $UI/QuizDialog
@onready var enemies_root: Node = $Enemies
@onready var items_root: Node = $Items


func _init() ->  void:
	randomize()


func _ready() -> void:
	if not OS.has_feature("editor"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN	
		
	for child in enemies_root.get_children():
		if child.has_signal("encountered"):
			child.encountered.connect(_on_enemy_encountered)

	for child in items_root.get_children():
		if child.has_signal("item_picked_up"):
			child.item_picked_up.connect(_on_item_picked_up)


func _on_enemy_encountered(enemy: Area2D) -> void:
	quiz.open_for(enemy)


func _on_item_picked_up(item: Item) -> void:
	item.queue_free()
