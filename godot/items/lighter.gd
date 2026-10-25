class_name Lighter
extends Item

@export var good_resource: GoodResource


func execute() -> void:
	CharacterManager.current.inventory.equip_good(good_resource)
	GameSession.has_lighter = true
	Sound.play(Sound.pickup_lighter)
	queue_free()
