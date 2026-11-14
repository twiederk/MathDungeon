extends Area2D


signal activated(goes_down: bool)

@export var goes_down: bool = false
@export var starts_disarmed: bool = false

var _armed: bool = true


func _ready() -> void:
	_armed = not starts_disarmed


func is_armed() -> bool:
	return _armed


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" or not _armed:
		return
	activated.emit(goes_down)


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_armed = true
