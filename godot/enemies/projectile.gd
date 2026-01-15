class_name Projectile
extends RigidBody2D

signal encountered(enemy: StaticBody2D)

@export var speed: float = 300.0
@export var damage: int = 1
@export var arrow_stats: EnemyStats = preload("res://enemies/arrow_stats.tres")

var direction: Vector2
var shooter: Enemy

@onready var hit_area: Area2D = $HitArea
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

# Create a temporary enemy-like object for the quiz system
class ArrowEnemy extends Enemy:
	var original_projectile: Projectile
	
	func _init(projectile: Projectile, enemy_stats: EnemyStats):
		stats = enemy_stats
		original_projectile = projectile
		# Set arrow to have 1 hit point initially
		hit_points = 1
	
	func hurt(_damage: int) -> int:
		# Arrow is always defeated in one hit, regardless of damage
		hit_points = 0
		return 0  # Return 0 hit points to indicate defeat


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
		# Create a temporary enemy object for the quiz system using arrow-specific stats
		var arrow_enemy = ArrowEnemy.new(self, arrow_stats)
		encountered.emit(arrow_enemy)
		# Free the arrow immediately after hitting the player
		queue_free()
	else:
		# Fallback: just remove the arrow if no shooter reference
		queue_free()


func _on_screen_exited() -> void:
	"""Clean up arrow when it leaves the screen"""
	queue_free()
