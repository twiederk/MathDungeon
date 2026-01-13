class_name DungeonTitle
extends Node2D

@export var title_text: String = "Dungeon Title"

@onready var animation_player = $TitleDisplay/AnimationPlayer
@onready var title_label = $TitleDisplay/TitleLabel
@onready var trigger_area_2d = $TriggerArea2D

var animation_triggered = false


func _ready() -> void:
	title_label.text = title_text


func _on_area_2d_body_entered(body: Node) -> void:
	if body.name == "Player" and not animation_triggered:
		title_label.visible = true
		animation_triggered = true
		animation_player.play("fade_out")
		trigger_area_2d.set_deferred("monitoring", false)


func _on_animation_finished(anim_name) -> void:
	queue_free()
