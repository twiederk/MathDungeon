class_name QuestLog


enum Status {
	OPEN,
	COMPLETED
}


var quests: Array[Quest] = [
	Quest.new("lighter", "Feuerzeug finden", "Aktiviere damit das Nether-Portal.", "lighter"),
	Quest.new("nether", "Ab in den Nether", "Durchschreite das aktivierte Nether-Portal.", "nether_1"),
	Quest.new("nether_fortress", "Nether-Festung erobern", "Besiege alle Gegner der Nether-Festung.", "nether_fortress"),
	Quest.new("dungeon", "Dungeon säubern", "Besiege alle Gegner eines Dungeons.", "dungeon"),
	Quest.new("woodland_mansion", "Waldanwesen erobern", "Besiege alle Bewohner des Waldanwesens.", "woodland_mansion"),
	Quest.new("eyes_of_ender", "12 Enderaugen einsammeln", "12 Enderaugen aktivieren das Endportal.", "eyes_12"),
	Quest.new("enderdragon", "Enderdrachen besiegen", "Durchschreite das Endportal und besiege den Enderdrachen.", "enderdragon_1"),
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
