class_name Projectile
extends RigidBody2D

signal encountered(enemy: StaticBody2D)

@export var speed: float = 300.0
@export var arrow_stats: EnemyStats = preload("res://enemies/arrow_stats.tres")

var direction: Vector2
var shooter: Enemy

@onready var hit_area: Area2D = $HitArea
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

class ProjectileEnemy extends Enemy:
	
	func _init(enemy_stats: EnemyStats):
		stats = enemy_stats
		hit_points = enemy_stats.max_hit_points
	
	func hurt(_damage: int) -> int:
		hit_points = 0
		return 0


func _ready() -> void:
	gravity_scale = 0
	lock_rotation = true


func initialize(start_position: Vector2, target_direction: Vector2, shooting_enemy: Enemy) -> void:
	position = start_position
	direction = target_direction.normalized()
	shooter = shooting_enemy
	rotation = direction.angle()
	linear_velocity = direction * speed


func _on_hit_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		var arrow_enemy = ProjectileEnemy.new(arrow_stats)
		encountered.emit(arrow_enemy)
		queue_free()
	else:
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
