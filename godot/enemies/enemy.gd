class_name Enemy
extends StaticBody2D


const HIT_EFFECT_SCENE := preload("res://enemies/hit_effect.tscn")

enum AttackType { NORMAL, SURPRISE }

@export var stats: EnemyStats
@export var location: String = ""
@export var flip_sprite: bool = false

signal encountered(enemy: StaticBody2D, attack_type: AttackType)
signal health_changed
signal defeated(enemy: Enemy)

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite: Sprite2D = $Sprite2D

@onready var hit_points: int = 5:
	set(value):
		hit_points = value
		health_changed.emit()


func _ready() -> void:
	hit_points = stats.get_max_hit_points()
	sprite.flip_h = flip_sprite
	detection_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		encountered.emit(self, _attack_type_for(body))


func _attack_type_for(player: Node2D) -> AttackType:
	var offset := player.global_position - global_position
	if absf(offset.x) > absf(offset.y):
		if _is_behind(offset.x):
			return AttackType.SURPRISE
		return AttackType.NORMAL
	if offset.y < 0.0:
		return AttackType.SURPRISE
	return AttackType.NORMAL


func _is_behind(horizontal_offset: float) -> bool:
	if flip_sprite:
		return horizontal_offset < 0.0
	return horizontal_offset > 0.0


func has_time_limit() -> bool:
	return stats.has_time_limit()


func hurt(damage: int) -> int:
	if is_inside_tree():
		Sound.play(stats.get_hurt_sound())
		_spawn_hit_effect()
	hit_points -= max(1, damage - stats.get_armor())
	if hit_points <= 0:
		defeated.emit(self)
	return hit_points


func _spawn_hit_effect() -> void:
	var effect := HIT_EFFECT_SCENE.instantiate()
	effect.global_position = global_position
	_effect_parent().add_child(effect)


func _effect_parent() -> Node:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node
