class_name Room
extends Branch

var entrances: Array[Vector2i] = []


func get_room_rect() -> Rect2i:
	return Rect2i(position + Vector2i.ONE, Vector2i(maxi(size.x - 1, 0), maxi(size.y - 1, 0)))


func get_floor_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var room_rect := get_room_rect()
	for x in range(room_rect.position.x, room_rect.end.x):
		for y in range(room_rect.position.y, room_rect.end.y):
			tiles.append(Vector2i(x, y))
	return tiles


func get_entrances() -> Array[Vector2i]:
	return entrances