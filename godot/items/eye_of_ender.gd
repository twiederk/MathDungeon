class_name EyeOfEnder
extends Item

@export var good_resource: GoodResource


func execute() -> void:
	CharacterManager.current.equip_good(good_resource)
	Sound.play(Sound.victory)
	queue_free()
