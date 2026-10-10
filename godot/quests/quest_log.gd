class_name QuestLog


enum Status {
	OPEN,
	COMPLETED
}


var quests: Array[Quest] = [
	Quest.new("lighter", "Feuerzeug finden", "Ohne Feuerzeug bleibt das Nether-Portal kalt.", "lighter"),
	Quest.new("nether", "Ab in den Nether", "Benötigt das Feuerzeug.", "nether_1"),
	Quest.new("nether_fortress", "Nether-Festung erobern", "Besiege alle Gegner der Festung.", "nether_fortress"),
	Quest.new("dungeon", "Dungeon säubern", "Besiege alle Gegner eines Dungeons.", "dungeon"),
	Quest.new("woodland_mansion", "Waldanwesen erobern", "Besiege alle Bewohner des Waldanwesens.", "woodland_mansion"),
	Quest.new("eyes_of_ender", "12 Augen des Enders sammeln", "Augen fallen von besiegten Gegnern.", "eyes_12"),
	Quest.new("enderdragon", "Enderdrachen besiegen", "Benötigt 12 Augen des Enders.", "enderdragon_1"),
]


func get_status(quest: Quest) -> Status:
	if quest.achievement_id in AchievementManager.unlocked_achievements:
		return Status.COMPLETED
	return Status.OPEN


func is_completed(quest: Quest) -> bool:
	return get_status(quest) == Status.COMPLETED


func get_progress(quest: Quest) -> Vector2i:
	var achievement = AchievementManager.ACHIEVEMENTS[quest.achievement_id]
	var current = AchievementManager.progress.get(achievement.type, 0)
	return Vector2i(mini(current, achievement.target), achievement.target)


func has_progress_bar(quest: Quest) -> bool:
	return AchievementManager.ACHIEVEMENTS[quest.achievement_id].target > 1
