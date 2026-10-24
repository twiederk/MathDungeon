class_name Helmet
extends Item

@export var armor: int
@export var item_id: String = ""


func execute() -> void:
	CharacterManager.current.inventory.equip_armor(item_id, armor)
	Sound.play(Sound.pickup_helmet)
	queue_free()
