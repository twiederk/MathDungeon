class_name RPGPlayer
extends Player

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree


func _update_visuals(direction: Vector2, _actual_velocity: Vector2) -> void:
	var is_moving := direction != Vector2.ZERO
	animation_tree.set("parameters/conditions/is_moving", is_moving)
	animation_tree.set("parameters/conditions/is_idle", not is_moving)
	if is_moving:
		animation_tree.set("parameters/move/blend_position", direction)
	if direction.x < 0:
		sprite_2d.flip_h = true
	elif direction.x > 0:
		sprite_2d.flip_h = false
