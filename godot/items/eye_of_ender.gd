class_name EyeOfEnder
extends Item

@export var good_resource: GoodResource


func execute() -> void:
	CharacterManager.current.inventory.equip_good(good_resource)
	GameSession.eyes_of_ender += 1
	Sound.play(Sound.victory)
	queue_free()
