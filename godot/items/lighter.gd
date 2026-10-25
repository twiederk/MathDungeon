class_name Lighter
extends Item

@export var good_resource: GoodResource


func execute() -> void:
	CharacterManager.current.equip_good(good_resource)
	Sound.play(Sound.pickup_lighter)
	queue_free()
