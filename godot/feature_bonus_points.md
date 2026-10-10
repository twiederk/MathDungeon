# Feature: Bonus Points for Location Achievements

## Goal

Clearing a whole location rewards the player with bonus score on top of the per-enemy score:

| Achievement | Bonus |
|---|---|
| `dungeon_0`, `dungeon_1`, `dungeon_2`, `dungeon_3` | 500 |
| `woodland_mansion` | 1.000 |
| `nether_fortress` | 1.500 |

> Superseded by [feature_quest_log.md](feature_quest_log.md) Phase 3: the four dungeon achievements
> were collapsed into a single `dungeon` achievement, still worth 500. It is `repeatable` — every
> cleared dungeon awards the bonus again, so "Double awarding" below no longer applies to it.

## Decisions

| Topic | Decision |
|---|---|
| Where the bonus is stored | As a `bonus: int` field on `AchievementManager.Achievement` — data-driven, no second lookup table |
| Who awards the points | `GameSession` listens to `achievement_unlocked`; `AchievementManager` stays free of game-state dependencies and testable in isolation |
| Double awarding | Prevented by the existing `unlocked_achievements` guard in `_unlock_achievement()` |
| Chained achievements | A bonus may push the score over a score milestone and unlock a second achievement — that is wanted |
| Popup text | The bonus is appended at runtime, not baked into `desc` |

## Current state

- `classic/achievement_manager.gd` (autoload) holds `ACHIEVEMENTS`, tracks `progress` per `type`
  and emits `achievement_unlocked(achievement)`.
- Location achievements are unlocked from `_track_location_defeat()` once the last enemy of a
  location dies (`_locations[location]` reaches 0).
- `classic/game_session.gd#add_score()` increases `score` and calls
  `AchievementManager.track_score(score)`.
- `gui/achievement_popup.gd` shows `title` and `desc` from the unlocked achievement.

## Phases

Each phase is independently shippable.

### Phase 1 — `bonus` field on `Achievement`

`classic/achievement_manager.gd`:

```gdscript
class Achievement:
	var title: String
	var desc: String
	var target: int
	var type: String
	var badge_graphic: String
	var bonus: int

	func _init(p_title: String, p_desc: String, p_target: int, p_type: String,
			p_badge_graphic: String = "", p_bonus: int = 0) -> void:
		title = p_title
		desc = p_desc
		target = p_target
		type = p_type
		badge_graphic = p_badge_graphic
		bonus = p_bonus
```

Set the values on the six location achievements:

```gdscript
"woodland_mansion": Achievement.new("Waldanwesen erobert!", "Besiege alle Bewohner des Waldanwesens", 1, "woodland_mansion", "score_1000.png", 1000),
"nether_fortress":  Achievement.new("Festung gesäubert!", "Besiege alle Gegner der Nether-Festung", 1, "nether_fortress", "score_1000.png", 1500),

"dungeon_0": Achievement.new("Dungeon 1 gesäubert!", "Besiege alle Gegner im ersten Dungeon", 1, "dungeon_0", "score_1000.png", 500),
"dungeon_1": Achievement.new("Dungeon 2 gesäubert!", "Besiege alle Gegner im zweiten Dungeon", 1, "dungeon_1", "score_1000.png", 500),
"dungeon_2": Achievement.new("Dungeon 3 gesäubert!", "Besiege alle Gegner im dritten Dungeon", 1, "dungeon_2", "score_1000.png", 500),
"dungeon_3": Achievement.new("Dungeon 4 gesäubert!", "Besiege alle Gegner im vierten Dungeon", 1, "dungeon_3", "score_1000.png", 500),
```

All other achievements keep the default `bonus = 0`, so nothing changes for them.

**Test:** `ACHIEVEMENTS["dungeon_0"].bonus == 500`, `woodland_mansion == 1000`,
`nether_fortress == 1500`, `score_1000.bonus == 0`.

### Phase 2 — Make `_check_progress_achievements()` reentrancy-safe

Awarding a bonus re-enters the manager:

```
track_enemy_defeat
  └─ _check_progress_achievements("dungeon_0")   # iterating ACHIEVEMENTS
       └─ _unlock_achievement → achievement_unlocked.emit
            └─ GameSession.add_score(500) → track_score
                 └─ _check_progress_achievements("score")
```

`ACHIEVEMENTS` itself is never mutated, so the outer loop stays valid — but the construct is
fragile. Collect first, unlock afterwards:

```gdscript
func _check_progress_achievements(type: String) -> void:
	var current = progress.get(type, 0)
	var to_unlock: Array[String] = []

	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id]
		if achievement.type == type and current >= achievement.target \
				and achievement_id not in unlocked_achievements:
			to_unlock.append(achievement_id)

	for achievement_id in to_unlock:
		_unlock_achievement(achievement_id)
```

`_unlock_achievement()` already appends to `unlocked_achievements` **before** emitting the signal.
That ordering must stay — it is what makes the recursive call idempotent.

**Test:** behaviour of the existing `test_AchievementManager.gd` suite stays green.

### Phase 3 — `GameSession` awards the bonus

`classic/game_session.gd`:

```gdscript
func _ready() -> void:
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(achievement: AchievementManager.Achievement) -> void:
	if achievement.bonus > 0:
		add_score(achievement.bonus)
```

Connecting in `_ready()` makes the autoload order in `project.godot` irrelevant.

**Tests** (`test/test_AchievementManager.gd`, extend `before_each` with `GameSession.reset()` so the
score does not leak between tests):

1. `test_clearing_dungeon_awards_bonus_score` — register one enemy with `location == "dungeon_0"`,
   defeat it, assert the score increased by 500.
2. `test_bonus_awarded_only_once` — defeating further enemies of the same location does not award
   the bonus again.
3. `test_woodland_mansion_awards_1000` / `test_nether_fortress_awards_1500`.
4. `test_no_bonus_for_unrelated_achievement` — unlocking a score achievement does not change the
   score (regression guard against infinite recursion).

### Phase 4 — Show the bonus in the popup

`gui/achievement_popup.gd#_show_next()`:

```gdscript
	title_label.text = achievement.title
	description_label.text = achievement.desc
	if achievement.bonus > 0:
		description_label.text += "\n+%d Punkte!" % achievement.bonus
```

### Phase 5 (optional) — Fix popup queue overlap

A bonus can unlock a score achievement immediately after the location achievement, so two popups
land in the queue back to back. `_show_next()` currently calls itself without awaiting the
animation, which makes them overlap:

```gdscript
	await _animation()
	_show_next()
```

This is a pre-existing bug that this feature makes clearly visible.

## Out of scope

- Persisting unlocked achievements across sessions (`SaveManager` is untouched).
- Bonus points for score milestones or enemy-type achievements.
- New badge graphics — the location achievements keep `score_1000.png`.

## Running the tests

```
cmd /c "test_ING.bat < nul"
```
