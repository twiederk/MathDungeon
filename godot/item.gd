class_name Item
extends Area2D

signal item_picked_up(item: Item)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		item_picked_up.emit(self)
