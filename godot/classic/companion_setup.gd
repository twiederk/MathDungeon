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
	var used: Array[Node] = []
	var companion_types := CharacterManager.current.companions

	for i in companion_types.size():
		if companion_types[i] == "Allay":
			# Allay: only queue_free existing instances, don't instantiate or follow
			var allay := _claim_allay(used)
			if allay:
				used.append(allay)
		else:
			# Wolf and other companions: claim/instantiate and make follow player
			var companion := _claim_companion(companion_types[i], used)
			if companion == null:
				continue
			used.append(companion)
			companion.global_position = _player.global_position + Vector2(60.0 + (i * 40.0), 0.0)
			companion.start_following(_player)


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
