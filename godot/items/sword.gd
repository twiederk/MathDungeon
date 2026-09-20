class_name Sword
extends Item

@export var damage: int


func execute() -> void:
	if damage > CharacterManager.current.weapon_damage:
		CharacterManager.current.weapon_damage = damage
	Sound.play(Sound.pickup_sword)
	queue_free()
