class_name Arrow
extends RigidBody2D

signal encountered(enemy: StaticBody2D)

@export var speed: float = 300.0
@export var damage: int = 1

var direction: Vector2
var shooter: Enemy

@onready var hit_area: Area2D = $HitArea
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	# Set up physics
	gravity_scale = 0
	lock_rotation = true

	# Connect signals
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	visible_notifier.screen_exited.connect(_on_screen_exited)


func initialize(start_position: Vector2, target_direction: Vector2, shooting_enemy: Enemy) -> void:
	"""Initialize the arrow with position, direction and shooter reference"""
	position = start_position
	direction = target_direction.normalized()
	shooter = shooting_enemy
	
	# Rotate sprite to match direction
	rotation = direction.angle()
	
	# Set velocity to start movement
	linear_velocity = direction * speed


func _on_hit_area_body_entered(body: Node) -> void:
	"""Handle collision with player"""
	if body.name == "Player":
		# Emit encountered signal using the shooter enemy reference
		if shooter:
			encountered.emit(shooter)
		# Remove the arrow after hitting player
		queue_free()


func _on_screen_exited() -> void:
	"""Clean up arrow when it leaves the screen"""
	queue_free()
