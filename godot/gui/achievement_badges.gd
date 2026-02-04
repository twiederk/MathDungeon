class_name AchievementBadges
extends Control


@onready var achievement_badges = $AchievementBadges


const MAX_BADGES: int = 5
const BADGE_SIZE: Vector2 = Vector2(32, 32)



var badge_nodes: Array[Panel] = []


func _ready() -> void:
	for i in range(MAX_BADGES):
		var badge = _create_badge_slot()
		achievement_badges.add_child(badge)
		badge_nodes.append(badge)
	
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	_update_badges()


func _create_badge_slot() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = BADGE_SIZE
	panel.modulate = Color(1, 1, 1, 0.3)
	
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = BADGE_SIZE
	texture_rect.anchors_preset = Control.PRESET_FULL_RECT
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	panel.add_child(texture_rect)
	
	return panel


func _on_achievement_unlocked(_achievement_id: String, _title: String, _description: String) -> void:
	_update_badges()
	_animate_newest_badge()


func _update_badges() -> void:
	var recent = AchievementManager.get_recent_unlocks()
	
	for i in range(MAX_BADGES):
		var texture_rect = badge_nodes[i].get_child(0) as TextureRect
		
		if i < recent.size():
			var achievement_id = recent[recent.size() - 1 - i]  # Reverse order (newest first)
			var achievement = AchievementManager.ACHIEVEMENTS.get(achievement_id, {})
			
			texture_rect.texture = load("res://gui/badget_1000.png")
			badge_nodes[i].modulate = Color.WHITE
		else:
			texture_rect.texture = null
			badge_nodes[i].modulate = Color(1, 1, 1, 0.3)


func _animate_newest_badge() -> void:
	if badge_nodes.is_empty():
		return
	
	var badge = badge_nodes[0]
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(badge, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(badge, "modulate:a", 1.0, 0.2)
	tween.chain()
	tween.tween_property(badge, "scale", Vector2(1.0, 1.0), 0.3)
	tween.set_parallel(false)
	
	tween.tween_property(badge, "rotation", TAU, 0.5)
	tween.tween_property(badge, "rotation", 0, 0.0)
