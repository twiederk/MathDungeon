class_name Player
extends CharacterBody2D

const SPEED: float = 200.0

func _physics_process(_delta: float) -> void:
	# Holt einen normierten Bewegungsvektor aus den UI-Inputs
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
