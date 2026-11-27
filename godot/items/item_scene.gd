class_name ItemScene
extends Area2D

signal item_picked_up(item: ItemScene)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		item_picked_up.emit(self)


func get_item_texture() -> AtlasTexture:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return null
	return sprite.texture as AtlasTexture


func get_item_resource() -> ItemResource:
	return null


func get_level() -> int:
	return ItemResource.INVALID_LEVEL


func execute() -> void:
	pass