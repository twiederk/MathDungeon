class_name GoodResource
extends Resource

enum GoodType { OTHER, HEALING_POTION }

@export var id: String = ""
@export var name: String = ""
@export var damage: int = 0
@export var good_type: GoodType = GoodType.OTHER
@export var icon_atlas: AtlasTexture
