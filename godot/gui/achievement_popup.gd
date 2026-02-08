class_name AchievementPopup
extends Control

const AUTO_HIDE_SECONDS: float = 4.0


@onready var panel_container: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var queue: Array[AchievementManager.Achievement] = []
var is_showing: bool = false


func _ready() -> void:
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(achievement_id: String, achievement: AchievementManager.Achievement) -> void:
	queue.append(achievement)
	
	if Sound.achievement_unlock:
		Sound.play(Sound.achievement_unlock)
	
	if not is_showing:
		_show_next()


func _show_next() -> void:
	if queue.is_empty():
		is_showing = false
		return
	
	is_showing = true
	var achievement = queue.pop_front()
	
	title_label.text = achievement.title
	description_label.text = achievement.desc

	_animation()
	_show_next()


func _animation() -> void:
	visible = true
	animation_player.play("slide_in")
	await get_tree().create_timer(AUTO_HIDE_SECONDS).timeout
	animation_player.play("slide_out")
	await animation_player.animation_finished
	visible = false
