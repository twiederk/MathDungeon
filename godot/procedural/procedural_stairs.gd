class_name ProceduralStairs
extends Area2D


signal activated(goes_down: bool)

@export var goes_down: bool = false

var _ignore_player_until_exit := false

func place_player(player: Player) -> void:
	_ignore_player_until_exit = true
	player.global_position = global_position


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if _ignore_player_until_exit:
		return
	activated.emit(goes_down)


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_ignore_player_until_exit = false
