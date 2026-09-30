class_name EnemyStats
extends Resource


enum ArithmeticType {
	ADDITION,
	SUBSTRACTION,
	MULTIPLICATION,
	DIVISION,
	DIVISION_REMAINDER,
	TIMES_TABLE,
	DIGIT_SUM,
	NUMBER_RIDDLE,
	NEXT_NUMBER,
	VOCABULARY,
	VOCABULARY_COLOR
}

const NOT_SET: int = -1

@export var name: String = "Enemie"
@export var max_hit_points: int = 1
@export var damage: int = 1
@export var armor: int = 0
@export var arithmetic: Array[ArithmeticType] = [ArithmeticType.ADDITION]
@export var max_number: int = 100
@export var time_limit: int = NOT_SET

@export_group("Hard")
@export var hard_max_hit_points: int = NOT_SET
@export var hard_damage: int = NOT_SET
@export var hard_armor: int = NOT_SET
@export var hard_arithmetic: Array[ArithmeticType] = []
@export var hard_max_number: int = NOT_SET
@export var hard_time_limit: int = 0


func get_max_hit_points() -> int:
	if _use_hard() and hard_max_hit_points >= 0:
		return hard_max_hit_points
	return max_hit_points


func get_damage() -> int:
	if _use_hard() and hard_damage >= 0:
		return hard_damage
	return damage


func get_armor() -> int:
	if _use_hard() and hard_armor >= 0:
		return hard_armor
	return armor


func get_arithmetic() -> Array[ArithmeticType]:
	if _use_hard() and not hard_arithmetic.is_empty():
		return hard_arithmetic
	return arithmetic


func get_max_number() -> int:
	if _use_hard() and hard_max_number >= 0:
		return hard_max_number
	return max_number


func get_time_limit() -> int:
	if _use_hard() and hard_time_limit != 0:
		return hard_time_limit
	return time_limit


func has_time_limit() -> bool:
	return get_time_limit() != NOT_SET


func get_score() -> int:
	var score: int = 0
	
	score += get_max_hit_points() * 2
	score += get_damage() * 2
	score += get_arithmetic().size() * 2
	score += get_armor() * 4
	
	var limit: int = get_time_limit()
	if limit != NOT_SET:
		score += (60 - limit) * 4
	
	return score


func _use_hard() -> bool:
	return PlayerStats.is_hard()
