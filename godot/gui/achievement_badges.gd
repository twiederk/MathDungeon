class_name AchievementBadges
extends HBoxContainer

## Display recent achievement badges with icons and animations

const MAX_BADGES: int = 5
const BADGE_SIZE: Vector2 = Vector2(32, 32)

# Badge colors for different achievement types
const BADGE_COLORS = {
	"score": Color(1.0, 0.843, 0.0),       # Gold
	"enderman": Color(0.502, 0.0, 0.502),  # Purple
	"enderdragon": Color(0.502, 0.0, 1.0), # Bright purple
	"nether": Color(1.0, 0.271, 0.0),      # Orange/Red
}

var badge_nodes: Array[Panel] = []


func _ready() -> void:
	# Create badge slots
	for i in range(MAX_BADGES):
		var badge = _create_badge_slot()
		add_child(badge)
		badge_nodes.append(badge)
	
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	_update_badges()


func _create_badge_slot() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = BADGE_SIZE
	panel.modulate = Color(1, 1, 1, 0.3)  # Semi-transparent when empty
	
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.text = "?"
	panel.add_child(label)
	
	return panel


func _on_achievement_unlocked(_achievement_id: String, _title: String, _description: String) -> void:
	_update_badges()
	_animate_newest_badge()


func _update_badges() -> void:
	var recent = AchievementManager.get_recent_unlocks()
	
	for i in range(MAX_BADGES):
		if i < recent.size():
			var achievement_id = recent[recent.size() - 1 - i]  # Reverse order (newest first)
			var achievement = AchievementManager.ACHIEVEMENTS.get(achievement_id, {})
			var badge_type = achievement.get("type", "score")
			
			badge_nodes[i].modulate = BADGE_COLORS.get(badge_type, Color.WHITE)
			var label = badge_nodes[i].get_child(0) as Label
			label.text = _get_badge_symbol(badge_type)
		else:
			badge_nodes[i].modulate = Color(1, 1, 1, 0.3)
			var label = badge_nodes[i].get_child(0) as Label
			label.text = "?"


func _get_badge_symbol(type: String) -> String:
	match type:
		"score":
			return "★"
		"enderman":
			return "E"
		"enderdragon":
			return "D"
		"nether":
			return "N"
		_:
			return "?"


func _animate_newest_badge() -> void:
	if badge_nodes.is_empty():
		return
	
	var badge = badge_nodes[0]
	
	# Create a quick glow/pulse animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(badge, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(badge, "modulate:a", 1.0, 0.2)
	tween.chain()
	tween.tween_property(badge, "scale", Vector2(1.0, 1.0), 0.3)
	tween.set_parallel(false)
	
	# Spin animation
	tween.tween_property(badge, "rotation", TAU, 0.5)
	tween.tween_property(badge, "rotation", 0, 0.0)
