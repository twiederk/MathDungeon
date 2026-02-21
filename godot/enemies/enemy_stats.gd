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

@export var name: String = "Enemie"
@export var max_hit_points: int = 1
@export var damage: int = 1
@export var armor: int = 0
@export var arithmetic: Array[ArithmeticType] = [ArithmeticType.ADDITION]
@export var max_number: int = 100
@export var time_limit: int = -1


func get_score() -> int:
	var score: int = 0
	
	score += max_hit_points * 2
	score += damage * 2
	score += arithmetic.size() * 2
	score += armor * 4
	
	if time_limit != -1:
		score += (60 - time_limit) * 4
	
	return score
