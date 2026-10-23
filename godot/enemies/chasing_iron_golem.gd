class_name ChasingIronGolem
extends CharacterBody2D


enum State { FRIENDLY, HOSTILE }

signal encountered(enemy: StaticBody2D, attack_type: Enemy.AttackType)
signal defeated(enemy: Enemy)

@export var aggro_radius: float = 220.0
@export var calm_down_distance: float = 500.0
@export var chase_speed: float = 180.0
@export var location: String = ""

@onready var enemy: Enemy = $IronGolem
@onready var sprite: Sprite2D = $IronGolem/Sprite2D

var state: State = State.FRIENDLY
var target: Player = null


func _ready() -> void:
	enemy.location = location
	enemy.encountered.connect(_on_enemy_encountered)
	enemy.defeated.connect(_on_enemy_defeated)


func _physics_process(_delta: float) -> void:
	if state != State.HOSTILE:
		return
	if target == null or not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) > calm_down_distance:
		_calm_down()
		return
	velocity = global_position.direction_to(target.global_position) * chase_speed
	move_and_slide()
	_update_sprite_direction(velocity.x)


func on_villager_defeated(villager_position: Vector2, player: Player) -> void:
	if state == State.HOSTILE:
		return
	if global_position.distance_to(villager_position) > aggro_radius:
		return
	state = State.HOSTILE
	target = player
	Sound.play(Sound.golem_hostile)


func _calm_down() -> void:
	state = State.FRIENDLY
	target = null
	velocity = Vector2.ZERO


func _update_sprite_direction(horizontal_direction: float) -> void:
	if horizontal_direction > 0:
		sprite.flip_h = true
	elif horizontal_direction < 0:
		sprite.flip_h = false


func _on_enemy_encountered(a_enemy: StaticBody2D, attack_type: Enemy.AttackType) -> void:
	encountered.emit(a_enemy, attack_type)


func _on_enemy_defeated(a_enemy: Enemy) -> void:
	defeated.emit(a_enemy)
	queue_free()
