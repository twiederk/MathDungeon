class_name Sword
extends Item

@export var damage: int
@export var item_id: String = ""


func execute() -> void:
	CharacterManager.current.inventory.equip_weapon(item_id, damage)
	Sound.play(Sound.pickup_sword)
	queue_free()
