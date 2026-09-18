class_name Branch

const SPLIT_PERCENT_MIN: float = 0.3
const SPLIT_PERCENT_MAX: float = 0.7

var position: Vector2i
var size: Vector2i
var left_child:  Branch
var right_child:  Branch


func _init(a_position, a_size) -> void:
	self.position = a_position
	self.size = a_size


func get_leaves() -> Array[Branch]:
	if is_leaf():
		return [self]
	else:
		return left_child.get_leaves() + right_child.get_leaves()


func is_leaf() -> bool:
	return not (left_child && right_child)


func get_center() -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(position.x + size.x / 2, position.y + size.y / 2)


func split(remaining: int, paths: Array[Dictionary]):
	var split_percent = randf_range(SPLIT_PERCENT_MIN, SPLIT_PERCENT_MAX)

	if (_should_split_horizontal()):
		# horizontal
		var left_height = int(size.y * split_percent)
		left_child = Branch.new(position, Vector2i(size.x, left_height))
		right_child = Branch.new(
			Vector2i(position.x, position.y + left_height), 
			Vector2i(size.x, size.y - left_height)
		)
	else:
		# vertical
		var left_width = int(size.x * split_percent)
		left_child = Branch.new(position, Vector2i(left_width, size.y))
		right_child = Branch.new(
			Vector2i(position.x + left_width, position.y), 
			Vector2i(size.x - left_width, size.y)
		)

	paths.push_back({'left': left_child.get_center(), 'right': right_child.get_center()})

	if (remaining > 0):
		left_child.split(remaining - 1, paths)
		right_child.split(remaining - 1, paths)


func _should_split_horizontal() -> bool:
	return size.y >= size.x
