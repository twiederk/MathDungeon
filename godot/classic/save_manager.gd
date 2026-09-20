extends Node

const CHARACTERS_DIR: String = "user://characters/"
const CHARACTERS_SAVE_VERSION: int = 2


func save_character(character: Character) -> void:
	# never persist a dead character; the stored copy always stays "alive"
	if character.hit_points <= 0:
		return
	DirAccess.make_dir_recursive_absolute(CHARACTERS_DIR)
	var data = {
		"version": CHARACTERS_SAVE_VERSION,
		"id": character.id,
		"display_name": character.display_name,
		"portrait_id": character.portrait_id,
		"max_hit_points": character.max_hit_points,
		"hit_points": character.hit_points,
		"weapon_damage": character.weapon_damage,
		"armor": character.armor,
		"companions": character.companions,
	}
	var save_file := FileAccess.open(_character_path(character.id), FileAccess.WRITE)
	save_file.store_string(JSON.stringify(data))
	save_file.close()


func load_and_activate_character(id: String) -> bool:
	var data = _read_character_data(id)
	if data == null:
		return false
	CharacterManager.current = _character_from_data(id, data)
	return true


func character_exists(id: String) -> bool:
	return FileAccess.file_exists(_character_path(id))


func _read_character_data(id: String):
	var path := _character_path(id)
	if not FileAccess.file_exists(path):
		return null
	var load_file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(load_file.get_line())
	load_file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return null
	return data


func _character_from_data(id: String, data: Dictionary) -> Character:
	var character := Character.new()
	# the filename is the trusted id; never trust a "id" field from inside the file
	character.id = _sanitize_id(id)
	var max_hit_points: int = int(data.get("max_hit_points", 5))
	character.load_state(
		str(data.get("display_name", "")),
		str(data.get("portrait_id", "")),
		max_hit_points,
		int(data.get("hit_points", max_hit_points)),
		int(data.get("weapon_damage", 1)),
		int(data.get("armor", 0)),
		_sanitize_string_array(data.get("companions", []))
	)
	# NOTE: portrait_id/companions are not yet validated against a catalog/database
	# (PortraitCatalog / CompanionDatabase land in later phases) - unknown ids are
	# kept as-is for now and simply won't resolve to anything visible.
	return character


func _character_path(id: String) -> String:
	return CHARACTERS_DIR + _sanitize_id(id) + ".save"


func _sanitize_id(id: String) -> String:
	# ids are always generated internally (never gamer-supplied); strip anything
	# that isn't a safe filename character to guard against a corrupted id list
	var regex := RegEx.new()
	regex.compile("[^a-zA-Z0-9_]")
	return regex.sub(id, "", true)


func _sanitize_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		if typeof(entry) == TYPE_STRING:
			result.append(entry)
	return result
