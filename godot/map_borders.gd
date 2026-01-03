class_name MapBorders
extends Node2D

@onready var north_border = $NorthBorder
@onready var south_border = $SouthBorder
@onready var west_border = $WestBorder
@onready var east_border = $EastBorder


func configure_borders() -> void:
	north_border.position = Vector2(0, -192)
	west_border.position = Vector2(-192, 0)
	south_border.position = Vector2(0, 1664)
	east_border.position = Vector2(1856, -192)
