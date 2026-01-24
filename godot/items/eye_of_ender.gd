class_name EyeOfEnder
extends Item


func execute() -> void:
	PlayerStats.eyes_of_ender += 1
	Sound.play(Sound.victory)
