class_name Companion
extends CharacterBody2D

signal companion_picked_up(companion: Companion)

@export var follow_speed: float = 150.0
@export var follow_distance: float = 80.0
@export var min_follow_distance: float = 40.0
@export var catch_up_margin: float = 1.15
@export var catch_up_distance: float = 150.0
@export var teleport_distance: float = 400.0

@onready var pickup_area: Area2D = $PickupArea
@onready var sprite_2d: Sprite2D = $Sprite2D

var is_following: bool = false
var player_reference: Player = null


func _ready() -> void:
	pickup_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_following and player_reference:
		_follow_player(delta)


func execute() -> void:
	pass


func start_following(player: Player) -> void:
	is_following = true
	player_reference = player


func _follow_player(_delta: float) -> void:
	if not player_reference:
		return
	
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	if distance_to_player > teleport_distance:
		global_position = player_reference.global_position
		velocity = Vector2.ZERO
		return
	
	if distance_to_player > follow_distance:
		var direction = (player_reference.global_position - global_position).normalized()
		velocity = direction * _current_follow_speed()
	elif distance_to_player < min_follow_distance:
		var direction = (global_position - player_reference.global_position).normalized()
		velocity = direction * follow_speed * 0.5
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	_update_sprite_direction(velocity.x)


func _current_follow_speed() -> float:
	var excess := global_position.distance_to(player_reference.global_position) - follow_distance
	var factor := clampf(excess / catch_up_distance, 0.0, 1.0)
	var top_speed := maxf(follow_speed, player_reference.velocity.length() * catch_up_margin)
	return lerpf(follow_speed, top_speed, factor)


func _update_sprite_direction(horizontal_direction: float) -> void:
	if horizontal_direction > 0:
		sprite_2d.flip_h = true
	elif horizontal_direction < 0:
		sprite_2d.flip_h = false


func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and not is_following:
		companion_picked_up.emit(self)
