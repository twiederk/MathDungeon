class_name FireworksEffect
extends Control

@onready var bursts: Node = $Bursts


func _ready() -> void:
	GameSession.highscore_rank_changed.connect(_on_highscore_rank_changed)


func _on_highscore_rank_changed(_rank: int) -> void:
	Sound.play(Sound.firework)
	for burst: GPUParticles2D in bursts.get_children():
		burst.emitting = true
