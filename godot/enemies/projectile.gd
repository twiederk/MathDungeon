class_name Projectile
extends RigidBody2D

signal encountered(enemy: StaticBody2D)

@export var speed: float = 300.0
@export var projectile_stats: EnemyStats

var direction: Vector2
var shooter: Enemy

@onready var hit_area: Area2D = $HitArea
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


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
		var enemy = Enemy.new()
		enemy.stats = projectile_stats
		enemy.hit_points = projectile_stats.max_hit_points
		encountered.emit(enemy)
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
