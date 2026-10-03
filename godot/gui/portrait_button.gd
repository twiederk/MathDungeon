class_name PortraitButton
extends Button


signal portrait_selected(portrait_id: String)

var portrait_id: String = ""

@onready var texture_rect: TextureRect = $TextureRect
@onready var selection_frame: Panel = $SelectionFrame


func _ready() -> void:
	pass


func setup(portrait: Portrait) -> void:
	portrait_id = portrait.id
	texture_rect.texture = portrait.texture
	set_meta("portrait_id", portrait.id)


func _on_pressed() -> void:
	portrait_selected.emit(portrait_id)


func highlight() -> void:
	selection_frame.visible = true


func unhighlight() -> void:
	selection_frame.visible = false
