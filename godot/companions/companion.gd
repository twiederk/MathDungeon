class_name Companion
extends Area2D

signal companion_picked_up(companion: Companion)

@export var follow_speed: float = 150.0
@export var follow_distance: float = 80.0
@export var min_follow_distance: float = 40.0

var is_following: bool = false
var player_reference: Player = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_following and player_reference:
		_follow_player(delta)


func execute() -> void:
	pass


func start_following(player: Player) -> void:
	is_following = true
	player_reference = player


func _follow_player(delta: float) -> void:
	if not player_reference:
		return
	
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	# Only move if too far from player
	if distance_to_player > follow_distance:
		var direction = (player_reference.global_position - global_position).normalized()
		global_position += direction * follow_speed * delta
	elif distance_to_player < min_follow_distance:
		# Move away if too close
		var direction = (global_position - player_reference.global_position).normalized()
		global_position += direction * follow_speed * 0.5 * delta


func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and not is_following:
		companion_picked_up.emit(self)
