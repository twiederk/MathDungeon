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
