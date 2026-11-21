class_name WorldLevelTitle
extends Control


@onready var title_label: Label = $TitleLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func show_title(text: String) -> void:
	title_label.text = text
	animation_player.play("reveal")


func _on_animation_finished(_animation_name: StringName) -> void:
	queue_free()
