class_name RPGPlayer
extends Player

@onready var sprite_2d: Sprite2D = $Sprite2D


func _update_visuals(direction: Vector2, _actual_velocity: Vector2) -> void:
	if direction.x > 0:
		sprite_2d.flip_h = true
	elif direction.x < 0:
		sprite_2d.flip_h = false
