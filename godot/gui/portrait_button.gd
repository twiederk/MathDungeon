class_name PortraitButton
extends Button


signal portrait_selected(portrait_id: String)

var portrait_id: String = ""

@onready var texture_rect: TextureRect = $TextureRect


func _ready() -> void:
	pass


func setup(portrait: Portrait) -> void:
	portrait_id = portrait.id
	texture_rect.texture = portrait.texture
	set_meta("portrait_id", portrait.id)


func _on_pressed() -> void:
	portrait_selected.emit(portrait_id)


func highlight() -> void:
	modulate = Color.YELLOW


func unhighlight() -> void:
	modulate = Color.WHITE
