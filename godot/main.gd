class_name Main
extends Node2D

@onready var quiz: Control = $UI/QuizDialog
@onready var enemies_root: Node = $Enemies

func _ready() -> void:
	# Alle vorhandenen Gegner im Enemies-Node durchgehen und Signal verbinden
	for child in enemies_root.get_children():
		if child.has_signal("encountered"):
			child.encountered.connect(_on_enemy_encountered)

func _on_enemy_encountered(enemy: Area2D) -> void:
	# Quiz öffnen, merkt sich den getroffenen Gegner
	quiz.open_for(enemy)
