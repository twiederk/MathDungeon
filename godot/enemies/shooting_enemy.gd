class_name ShootingEnemy
extends Enemy

@export var fire_delays: Array[float] = [2.0]
@export var projectile_scene: PackedScene

@onready var fire_timer: Timer = $FireTimer
@onready var shooting_area: Area2D = $ShootingArea

var is_shooting: bool = false
var player_target: Node = null
var _delay_index: int = 0


func _on_shooting_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_target = body
		_start_shooting()


func _on_shooting_area_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_target = null
		_stop_shooting()


func _start_shooting() -> void:
	if not is_shooting:
		is_shooting = true
		_delay_index = 0
		call_deferred("_shoot_arrow")
		_restart_fire_timer()


func _stop_shooting() -> void:
	is_shooting = false
	fire_timer.stop()


func _restart_fire_timer() -> void:
	if fire_delays.is_empty():
		return
	fire_timer.wait_time = fire_delays[_delay_index]
	_delay_index = (_delay_index + 1) % fire_delays.size()
	fire_timer.start()


func _on_fire_timer_timeout() -> void:
	if not is_shooting:
		return
	if player_target:
		_shoot_arrow()
	_restart_fire_timer()


func _shoot_arrow() -> void:
	if not projectile_scene or not player_target:
		return
	var projectile = projectile_scene.instantiate()	
	var direction = (player_target.global_position - global_position).normalized()	
	get_parent().add_child(projectile)
	projectile.initialize(global_position, direction, self)
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("_on_enemy_encountered"):
		projectile.encountered.connect(main_scene._on_enemy_encountered)
