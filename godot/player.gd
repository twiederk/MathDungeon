class_name Player
extends CharacterBody2D

const SPEED: float = 200.0

@onready var camera_2d: Camera2D = $Camera2D


func _physics_process(_delta: float) -> void:
	# Holt einen normierten Bewegungsvektor aus den UI-Inputs
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()


func set_camera_limits(north_limit: float, south_limit: float, west_limit: float, east_limit: float) -> void:
	camera_2d.set_limit(SIDE_LEFT, int(west_limit))
	camera_2d.set_limit(SIDE_RIGHT, int(east_limit))
	camera_2d.set_limit(SIDE_TOP, int(north_limit))
	camera_2d.set_limit(SIDE_BOTTOM, int(south_limit))
