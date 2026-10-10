class_name Quest


var id: String
var title: String
var hint: String
var achievement_id: String


func _init(p_id: String, p_title: String, p_hint: String, p_achievement_id: String) -> void:
	id = p_id
	title = p_title
	hint = p_hint
	achievement_id = p_achievement_id
