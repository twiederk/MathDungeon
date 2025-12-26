class_name Enemy
extends Area2D

@export var monster_stats: MonsterStats

signal encountered(enemy: Area2D)

@onready var enemies_root: Node = $Enemies


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		encountered.emit(self)
