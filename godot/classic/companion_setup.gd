class_name CompanionSetup
extends Object


const COMPANION_SCENES := {
	"Wolf": "res://companions/wolf.tscn",
}

var _companions_root: Node
var _player: Player


func _init(companions_root: Node, player: Player) -> void:
	_companions_root = companions_root
	_player = player


func setup() -> void:
	var used_companion_nodes: Array[Node] = []
	var companions := CharacterManager.current.companions

	for index in companions.size():
		if companions[index] == "Allay":
			_mark_allay_used(used_companion_nodes)
		else:
			_place_companion(companions[index], index, used_companion_nodes)

	_free_allays(used_companion_nodes)


func _mark_allay_used(used: Array[Node]) -> void:
	var allay := _claim_allay(used)
	if allay != null:
		used.append(allay)


func _place_companion(companion_type: String, index: int, used: Array[Node]) -> void:
	var companion := _claim_companion(companion_type, used)
	if companion == null:
		return
	used.append(companion)
	companion.global_position = _player.global_position + Vector2(60.0 + (index * 40.0), 0.0)
	companion.start_following(_player)


func _free_allays(used: Array[Node]) -> void:
	for node in used:
		if String(node.get_script().get_global_name()) == "Allay":
			node.queue_free()


func _claim_allay(used: Array[Node]) -> Companion:
	for child in _companions_root.get_children():
		if child in used or not child is Companion:
			continue
		if String(child.get_script().get_global_name()) == "Allay":
			return child
	return null


func _claim_companion(companion_type: String, used: Array[Node]) -> Companion:
	for child in _companions_root.get_children():
		if child in used or not child is Companion:
			continue
		if String(child.get_script().get_global_name()) == companion_type:
			return child

	var companion := _instantiate_companion(companion_type)
	if companion:
		_companions_root.add_child(companion)
	return companion


func _instantiate_companion(companion_type: String) -> Companion:
	var scene: PackedScene = load(COMPANION_SCENES[companion_type])
	var instance := scene.instantiate()
	return instance
