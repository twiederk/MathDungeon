class_name Generator


enum Tier { EASY, MEDIUM, HARD }


const EASY_TIER_END_PROGRESS: float = 0.5
const HARD_TIER_START_PROGRESS: float = 0.75


func _get_room_tier(room_progress: float) -> int:
	if room_progress <= EASY_TIER_END_PROGRESS:
		return Tier.EASY
	if room_progress < HARD_TIER_START_PROGRESS:
		return Tier.MEDIUM
	return Tier.HARD


func _get_eligible_content_levels(level: int, tier: int) -> Array[int]:
	var eligible_levels: Array[int] = []
	match tier:
		Tier.EASY:
			eligible_levels.assign([level - 1, level])
		Tier.MEDIUM:
			eligible_levels.assign([level])
		Tier.HARD:
			eligible_levels.assign([level, level + 1])
	return eligible_levels