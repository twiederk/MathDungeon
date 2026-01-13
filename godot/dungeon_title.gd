class_name DungeonTitle
extends Node2D

@export var title_text: String = "Dungeon Title"

@onready var animation_player = $TitleDisplay/AnimationPlayer
@onready var label = $TitleDisplay/Label
@onready var area_2d = $Area2D

var animation_triggered = false


func _ready():
	label.text = title_text
	animation_player.animation_finished.connect(_on_animation_finished)


func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and not animation_triggered:
		animation_triggered = true
		animation_player.play("fade_out")
		# Disable the area after triggering
		area_2d.set_deferred("monitoring", false)


func _on_animation_finished():
	queue_free()
