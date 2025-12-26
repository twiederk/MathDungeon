class_name EnemyStats
extends Resource

enum ArithmeticType {
	ADDITION,
	SUBSTRACTION,
	MULTIPLICATION,
	DIVISION
}

@export var name: String = "Enemie"
@export var max_hit_points: int = 1
@export var damage: int = 1
@export var armor: int = 0
@export var arithmetic: Array[ArithmeticType] = [ArithmeticType.ADDITION]
@export var max_number: int = 100
@export var time_limit: int = -1
