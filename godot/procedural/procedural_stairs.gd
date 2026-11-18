extends Area2D


signal activated(goes_down: bool)

@export var goes_down: bool = false


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	activated.emit(goes_down)
