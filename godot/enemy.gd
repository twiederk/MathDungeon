class_name Enemy
extends Area2D

signal encountered(enemy: Area2D)

func _ready() -> void:
	# verbindet das eingebaute Signal body_entered mit unserer Funktion
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Prüfen, ob der Player hineinläuft
	if body.name == "Player":
		encountered.emit(self)
