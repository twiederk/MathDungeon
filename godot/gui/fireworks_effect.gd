class_name FireworksEffect
extends Control

@onready var bursts: Node = $Bursts


func _ready() -> void:
	GameSession.entered_highscores.connect(_on_entered_highscores)


func _on_entered_highscores() -> void:
	Sound.play(Sound.firework)
	for burst: GPUParticles2D in bursts.get_children():
		burst.emitting = true
