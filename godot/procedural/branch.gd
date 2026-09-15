class_name Branch


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


func split(remaining):
	var rng = RandomNumberGenerator.new()
	var split_percent = rng.randf_range(0.3, 0.7) # splits will be between 30% and 70%
	var split_horizontal = size.y >= size.x # if it is taller than it is wide

	if (split_horizontal):
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

	if (remaining > 0):
		left_child.split(remaining - 1)
		right_child.split(remaining - 1)
