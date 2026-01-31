class_name AchievementPopup
extends Control

## Achievement notification popup
## Shows a banner with title and description when an achievement is unlocked

@onready var panel_container: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var queue: Array[Dictionary] = []
var is_showing: bool = false


func _ready() -> void:
	visible = false
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(achievement_id: String, title: String, description: String) -> void:
	queue.append({"id": achievement_id, "title": title, "desc": description})
	
	# Play victory sound for achievement unlock
	if Sound.victory:
		Sound.play(Sound.victory)
	
	if not is_showing:
		_show_next()


func _show_next() -> void:
	if queue.is_empty():
		is_showing = false
		return
	
	is_showing = true
	var achievement = queue.pop_front()
	
	title_label.text = achievement["title"]
	description_label.text = achievement["desc"]
	
	visible = true
	animation_player.play("slide_in")
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	animation_player.play("slide_out")
	await animation_player.animation_finished
	visible = false
	
	# Show next in queue
	_show_next()
