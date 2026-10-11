class_name QuestLog


enum Status {
	OPEN,
	COMPLETED
}


var quests: Array[Quest] = [
	Quest.new("dungeon", "Erobere ein Dungeon", "Besiege alle Gegner eines Dungeons.", "dungeon"),
	Quest.new("woodland_mansion", "Erobere das Waldanwesen", "Besiege alle Bewohner des Waldanwesens.", "woodland_mansion"),
	Quest.new("lighter", "Aktivere das Nether-Portal", "Finde das Feuerzeug und aktiviere das Nether-Portal.", "lighter"),
	Quest.new("nether", "Betritt den Nether", "Durchschreite das aktivierte Nether-Portal.", "nether"),
	Quest.new("nether_fortress", "Erobere die Nether-Festung", "Besiege alle Gegner der Nether-Festung.", "nether_fortress"),
	Quest.new("eyes_of_ender", "Aktiviere das Endportal", "Sammle 12 Enderaugen, um das Endportal zu aktivieren.", "eyes_12"),
	Quest.new("enderdragon", "Besiege den Enderdrachen", "Durchschreite das Endportal und besiege den Enderdrachen.", "enderdragon"),
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
