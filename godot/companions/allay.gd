class_name Allay
extends Companion


func execute() -> void:
	Sound.play(Sound.dog_bark)
	CharacterManager.current.armor += 1
	await get_tree().create_timer(30.0).timeout
	queue_free()
