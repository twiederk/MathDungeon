class_name Helmet
extends Item

@export var armor: int


func execute() -> void:
	if armor > PlayerStats.armor:
		PlayerStats.armor = armor	
	Sound.play(Sound.pickup_helmet)
