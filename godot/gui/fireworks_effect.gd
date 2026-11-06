class_name FireworksEffect
extends Control

@onready var bursts: Node = $Bursts


func _ready() -> void:
	GameSession.highscore_rank_changed.connect(_on_highscore_rank_changed)


func _on_highscore_rank_changed(rank: int) -> void:
	if rank == HighscoreManager.NO_RANK:
		return
	Sound.play(Sound.firework)
	for burst: GPUParticles2D in bursts.get_children():
		burst.emitting = true
