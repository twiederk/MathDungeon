class_name AchievementBadges
extends Control


@onready var achievement_badges = $AchievementBadges


const BADGE_GRAPHICS_PATH: String = "res://gui/badges/"


var badge_nodes: Array[Panel] = []


func _ready() -> void:
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	_setup_badge_nodes()
	_update_badges()


func _on_achievement_unlocked(_achievement: AchievementManager.Achievement) -> void:
	_update_badges()
	_animate_newest_badge()


func _setup_badge_nodes() -> void:
	for i in range(achievement_badges.get_child_count()):
		var badge = achievement_badges.get_child(i) as Panel
		badge_nodes.append(badge)


func _update_badges() -> void:
	var recent = AchievementManager.get_recent_unlocks()
	
	for i in range(badge_nodes.size()):
		var texture_rect = badge_nodes[i].get_child(0) as TextureRect
		
		if i < recent.size():
			var achievement_id = recent[recent.size() - 1 - i]  # Reverse order (newest first)
			var badge_graphic = _get_badge_graphic(achievement_id)
			
			texture_rect.texture = load(badge_graphic)
			badge_nodes[i].modulate = Color.WHITE
		else:
			texture_rect.texture = null
			badge_nodes[i].modulate = Color(1, 1, 1, 0.3)


func _get_badge_graphic(achievement_id: String) -> String:
	if achievement_id in AchievementManager.ACHIEVEMENTS:
		var achievement = AchievementManager.ACHIEVEMENTS[achievement_id]
		if achievement.badge_graphic != "":
			return BADGE_GRAPHICS_PATH + achievement.badge_graphic
	return BADGE_GRAPHICS_PATH + "badge_1000.png"


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
