class_name Lighter
extends Item

@export var good_resource: GoodResource


func execute() -> void:
	CharacterManager.current.inventory.equip_good(good_resource)
	CharacterManager.current.has_lighter = true
	Sound.play(Sound.pickup_lighter)
	queue_free()
