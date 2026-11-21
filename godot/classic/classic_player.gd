class_name ClassicPlayer
extends Player

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree


func apply_portrait(portrait: Portrait) -> void:
	sprite_2d.texture = portrait.idle_texture


func _update_visuals(direction: Vector2, _actual_velocity: Vector2) -> void:
	var is_moving := direction != Vector2.ZERO
	animation_tree.set("parameters/conditions/is_moving", is_moving)
	animation_tree.set("parameters/conditions/is_idle", not is_moving)
	_update_sprite_direction(direction.x)


func _update_sprite_direction(horizontal_direction: float) -> void:
	if horizontal_direction > 0:
		sprite_2d.flip_h = true
	elif horizontal_direction < 0:
		sprite_2d.flip_h = false
