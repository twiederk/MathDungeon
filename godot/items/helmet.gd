class_name Helmet
extends Item

@export var armor: int


func execute() -> void:
	if armor > CharacterManager.current.armor:
		CharacterManager.current.armor = armor	
	Sound.play(Sound.pickup_helmet)
	queue_free()
