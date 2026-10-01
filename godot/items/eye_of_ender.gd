class_name EyeOfEnder
extends Item


func execute() -> void:
	GameSession.eyes_of_ender += 1
	Sound.play(Sound.victory)
	queue_free()
