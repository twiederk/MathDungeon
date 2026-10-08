class_name LootDropper


func drop_items(enemy: Enemy, items_root: Node) -> Array[Item]:
	var dropped_items: Array[Item] = []
	for drop_definition in enemy.stats.loot_drops:
		if drop_definition == null or drop_definition.item_scene == null:
			continue

		if _drop_roll(drop_definition.probability):
			var item := drop_definition.item_scene.instantiate() as Item
			items_root.add_child(item)
			item.global_position = enemy.global_position
			dropped_items.append(item)

	return dropped_items


func _drop_roll(probability: float) -> bool:
	if probability < 0.0 or probability > 1.0:
		return false
	if probability == 0.0:
		return false
	if probability == 1.0:
		return true
	return randf() < probability