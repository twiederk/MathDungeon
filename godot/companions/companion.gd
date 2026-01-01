class_name Companion
extends Area2D

signal companion_picked_up(companion: Companion)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func execute() -> void:
	pass


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		companion_picked_up.emit(self)
