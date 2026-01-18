class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
const SPRINT_MULTIPLIER: float = 1.4

@onready var camera_2d: Camera2D = $Camera2D


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * _speed()
	move_and_slide()


func _speed() -> float:
	if Input.is_action_pressed("sprint"):
		return SPEED * SPRINT_MULTIPLIER
	return SPEED


func set_camera_limits(north_limit: float, south_limit: float, west_limit: float, east_limit: float) -> void:
	camera_2d.set_limit(SIDE_LEFT, int(west_limit))
	camera_2d.set_limit(SIDE_RIGHT, int(east_limit))
	camera_2d.set_limit(SIDE_TOP, int(north_limit))
	camera_2d.set_limit(SIDE_BOTTOM, int(south_limit))
