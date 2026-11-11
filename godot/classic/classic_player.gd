class_name ClassicPlayer
extends Player

@onready var sprite_2d: Sprite2D = $Sprite2D


func apply_portrait(texture: Texture2D) -> void:
	sprite_2d.texture = texture


func _update_visuals(direction: Vector2, _actual_velocity: Vector2) -> void:
	_update_sprite_direction(direction.x)


func _update_sprite_direction(horizontal_direction: float) -> void:
	if horizontal_direction > 0:
		sprite_2d.flip_h = true
	elif horizontal_direction < 0:
		sprite_2d.flip_h = false