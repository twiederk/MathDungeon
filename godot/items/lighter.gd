class_name Lighter
extends Item


func execute() -> void:
	CharacterManager.current.set_has_lighter(true)
	Sound.play(Sound.pickup_lighter)
	queue_free()
