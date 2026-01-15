class_name ShootingSkeleton
extends Enemy

@export var fire_rate: float = 2.0  # Seconds between shots
@export var shooting_range: float = 200.0  # Maximum shooting distance
@export var arrow_scene: PackedScene = preload("res://enemies/arrow.tscn")

@onready var fire_timer: Timer = $FireTimer
@onready var shooting_area: Area2D = $ShootingArea

var is_shooting: bool = false
var player_target: Node = null

func _ready() -> void:
	super._ready()
	
	# Set up fire timer
	fire_timer.wait_time = fire_rate
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	
	# Set up shooting area for detecting when player enters shooting range
	shooting_area.body_entered.connect(_on_shooting_area_body_entered)
	shooting_area.body_exited.connect(_on_shooting_area_body_exited)

func _on_shooting_area_body_entered(body: Node) -> void:
	"""Start shooting when player enters the shooting area"""
	if body.name == "Player":
		player_target = body
		_start_shooting()

func _on_shooting_area_body_exited(body: Node) -> void:
	"""Stop shooting when player leaves the shooting area"""
	if body.name == "Player":
		player_target = null
		_stop_shooting()

func _start_shooting() -> void:
	"""Begin the shooting sequence"""
	if not is_shooting:
		is_shooting = true
		# Defer the first shot to avoid physics query conflicts
		call_deferred("_shoot_arrow")
		# Then start the timer for subsequent shots
		fire_timer.start()

func _stop_shooting() -> void:
	"""Stop the shooting sequence"""
	is_shooting = false
	fire_timer.stop()

func _on_fire_timer_timeout() -> void:
	"""Fire an arrow at the player"""
	if is_shooting and player_target:
		_shoot_arrow()

func _shoot_arrow() -> void:
	"""Create and launch an arrow towards the player"""
	if not arrow_scene or not player_target:
		return
	
	# Create arrow instance
	var arrow = arrow_scene.instantiate()
	
	# Calculate direction to player
	var direction = (player_target.global_position - global_position).normalized()
	
	# Add arrow to the scene (as sibling of this enemy)
	get_parent().add_child(arrow)
	
	# Initialize arrow with position, direction, and shooter reference
	arrow.initialize(global_position, direction, self)
	
	# Connect arrow's encountered signal to main scene's handler
	# Find the main scene and connect the arrow's signal
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("_on_enemy_encountered"):
		arrow.encountered.connect(main_scene._on_enemy_encountered)
