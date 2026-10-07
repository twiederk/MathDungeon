class_name Allay
extends Companion


func execute() -> void:
	Sound.play(Sound.companion_ally)
	CharacterManager.current.armor += 1
	await get_tree().create_timer(12.0).timeout
	var disappear_tween := create_tween()
	disappear_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await disappear_tween.finished
	queue_free()
