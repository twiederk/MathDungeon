# Feature: Quest Log

## Goal

Give the run a readable narrative. The player opens a **quest log** with `F1` and sees the chain of
goals that leads from the first pickup to the Enderdragon, each marked `OPEN` or `COMPLETED`, with
a progress counter where one exists ("Augen des Enders: 7 / 12").

Completing a quest unlocks an achievement — which is already how most of these goals work today.

## Decisions

| Topic | Decision |
|---|---|
| Source of truth | `AchievementManager`. A quest has **no own state**; its status is derived |
| Quest completion | Identical to "its achievement is unlocked" |
| Status values | `OPEN` / `COMPLETED`. All quests are visible from the start |
| Quest chain | Expressed by **list order and hint text**, not by a locked state |
| Progress display | Read `AchievementManager.progress[type]` against `Achievement.target` |
| Persistence | **None.** The quest log shows the current run only, like achievements |
| Lifecycle | `AchievementManager.reset()` resets the quest log implicitly |
| Lighter / eyes of ender | Per-run state on `GameSession`, not on `Character` |
| Enderman achievements | Replaced by eyes-of-ender achievements (4 / 8 / 12) |
| Dungeon achievements | The four `dungeon_0..3` achievements collapse into one `dungeon` |
| Input | New `quest_log` input action, bound to `F1` (desktop only, no web export) |

### Consequence: quests are metadata, not state

Because completion means "the achievement is unlocked", a second set of counters would be a second
source of truth that can drift from the first. `QuestLog` therefore stores only title, hint and
`achievement_id`, and computes everything else on demand.

### Why no `LOCKED` state

Only two quests have a real prerequisite, and the world already teaches both: the Nether portal
cannot be lit without the lighter, the End portal needs 12 eyes. Hiding those quests would withhold
information the player discovers by walking into the portal anyway, and a greyed-out row reads as
"broken" to a young player. The chain is conveyed by list order plus a hint line
("Benötigt das Feuerzeug.") instead.

A recursive prerequisite check also loops forever on a cyclic `requires` — a real crash risk for
almost no gain. Since status is derived, `LOCKED` can be added later without a migration if
playtesting shows the full list overwhelms players.

## Current state

- `AchievementManager` ([classic/achievement_manager.gd](classic/achievement_manager.gd)) already
  tracks `score`, `enderman`, `enderdragon`, `nether` plus the location-based achievements
  `woodland_mansion`, `nether_fortress` and `dungeon_0..3`.
- `_track_location_defeat()` keys both `_locations` and `progress` by the raw `enemy.location`
  string, which comes from the `.tscn` files.
- `GameSession.eyes_of_ender` is per-run and already emits `eyes_of_ender_changed`.
- **Bug:** the lighter lives on `Character` as `_has_lighter`. `CharacterManager.current` is loaded
  once in `_ready()` and never reloaded, and nothing in `start_menu.gd` clears it — so after one
  successful run every later run starts with the Nether portal already open. The setter also calls
  `SaveManager.save_character()`, a disk write that persists nothing, because the v2 schema has no
  lighter field and `load_state()` never restores it.
- `test/test_Lighter.gd` works around this by calling `set_has_lighter(false)` in its setup.

## Phases

Each phase is independently shippable.

### ✅ Phase 1 — Move the lighter to `GameSession` (bug fix)

Add run state mirroring `eyes_of_ender`:

```gdscript
signal has_lighter_changed

var has_lighter: bool = false:
	set(value):
		has_lighter = value
		has_lighter_changed.emit()
```

Clear it in `GameSession.reset()`.

Remove `_has_lighter`, `set_has_lighter()`, `has_lighter_changed` and `has_item()` from `Character`.
Without the lighter, `has_item()` would always return `false`, so it is dropped rather than left as
dead code — [feature_inventory_system.md](feature_inventory_system.md) Phase 9 reintroduces it for
persistent gear (sword, helmet), where it belongs. The lighter never did.

Call sites: [items/lighter.gd](items/lighter.gd) sets `GameSession.has_lighter = true`,
[locations/nether_portal.gd](locations/nether_portal.gd) reads it.

Tests: drop the `set_has_lighter(false)` workaround from `test/test_Lighter.gd`, and add a
regression test asserting `GameSession.reset()` clears the lighter.

Boundary after this phase:

- `Character` — persists across runs (gear, companions, hit points)
- `GameSession` — per run (score, eyes of ender, lighter)

### ✅ Phase 2 — Eyes of ender replace the Enderman achievements

Remove `"enderman"` from `progress`, from `reset()` and from `_track_enemy_type_defeat()`, and drop
`enderman_1 / enderman_5 / enderman_10`.

Add:

```gdscript
"eyes_4": Achievement.new("Vier Augen", "Sammle 4 Augen des Enders", 4, "eyes_of_ender", ""),
"eyes_8": Achievement.new("Acht Augen", "Sammle 8 Augen des Enders", 8, "eyes_of_ender", ""),
"eyes_12": Achievement.new("Das Endportal ruft!", "Sammle 12 Augen des Enders", 12, "eyes_of_ender", "", 1000),
"lighter": Achievement.new("Feuerzeug gefunden!", "Finde das Feuerzeug", 1, "lighter", "lighter.png", 250),
```

Both are driven by signals, so no item script needs to call the `AchievementManager` at all:

```gdscript
func _ready() -> void:
	GameSession.eyes_of_ender_changed.connect(_on_eyes_of_ender_changed)
	GameSession.has_lighter_changed.connect(_on_has_lighter_changed)

func _set_progress(type: String, value: int) -> void:
	progress[type] = value
	_check_progress_achievements(type)
```

Absolute values, not increments — same contract as `track_score()`, so no double counting against
`GameSession`. Autoload order already has `GameSession` before `AchievementManager`.

**Assets — outstanding:** the four new achievements ship with an empty `badge_graphic`, so
`AchievementBadges._get_badge_graphic()` falls back to `score_1000.png`. Create
`eyes_4/8/12.png` and `lighter.png` in [gui/badges](gui/badges) and fill the field in. The now
unused `enderman_1/5/10.png` are left in place as source art for the eye badges.

Tests: rewrite the Enderman cases in `test/test_AchievementManager.gd` against
`GameSession.eyes_of_ender`.

### ✅ Phase 3 — One dungeon achievement

Keep `_locations` keyed by the individual location so the "all enemies defeated" counting still
works per dungeon, but normalise to one achievement type:

```gdscript
func _location_to_type(location: String) -> String:
	return "dungeon" if location.begins_with("dungeon") else location
```

Replace `dungeon_0..3` with a single
`"dungeon": Achievement.new("Dungeon gesäubert!", "Besiege alle Gegner eines Dungeons", 1, "dungeon", "conquere_dungeon.png", 500, true)`.

The trailing `true` is a new `repeatable` flag on `Achievement`. Clearing a dungeon is a *repeatable
deed*, not a one-off milestone: every cleared dungeon fires `achievement_unlocked` again and awards
the bonus again, including the same dungeon on a second visit. `unlocked_achievements` still holds
the id only once, so the quest log's `COMPLETED` check is unaffected.

The `_locations` guard still prevents double counting within one visit — re-arming happens in
`WorldLevel._setup_locations()`, which clears and re-registers on every level load.

**Score balance:** the bonus stays at 500 per dungeon, but is no longer capped at 4 × 500 — a
player who revisits dungeons can farm it. Reconcile with
[feature_bonus_points.md](feature_bonus_points.md).

Tests: `test/test_AchievementManager.gd` currently asserts `"dungeon_0" in unlocked_achievements`
— update to `"dungeon"`, and cover both halves of the flag: a second dungeon awards the bonus
again, a second woodland mansion does not.

### Phase 4 — `Quest` and `QuestLog`

`quests/quest.gd` — data only, `RefCounted`:

```gdscript
class_name Quest
extends RefCounted

var id: String
var title: String
var hint: String              # what to do next, incl. any prerequisite
var achievement_id: String
```

`quests/quest_log.gd` — derived status, no stored state, no autoload needed:

```gdscript
enum Status { OPEN, COMPLETED }

func get_status(quest: Quest) -> Status:
	return Status.COMPLETED if quest.achievement_id in AchievementManager.unlocked_achievements else Status.OPEN

func get_progress(quest: Quest) -> Vector2i:
	var achievement = AchievementManager.ACHIEVEMENTS[quest.achievement_id]
	return Vector2i(AchievementManager.progress.get(achievement.type, 0), achievement.target)
```

`QUESTS` is an ordered `Array[Quest]` — the array order *is* the chain order shown in the UI:

| # | Quest | `achievement_id` | Hint |
|---|---|---|---|
| 1 | Feuerzeug finden | `lighter` | Ohne Feuerzeug bleibt das Nether-Portal kalt. |
| 2 | Ab in den Nether | `nether_1` | Benötigt das Feuerzeug. |
| 3 | Nether-Festung erobern | `nether_fortress` | Besiege alle Gegner der Festung. |
| 4 | Dungeon säubern | `dungeon` | Besiege alle Gegner eines Dungeons. |
| 5 | Waldanwesen erobern | `woodland_mansion` | Besiege alle Bewohner des Waldanwesens. |
| 6 | 12 Augen des Enders sammeln | `eyes_12` | Augen fallen von besiegten Gegnern. |
| 7 | Enderdrachen besiegen | `enderdragon_1` | Benötigt 12 Augen des Enders. |

Tests: `test/test_QuestLog.gd` drives `AchievementManager` and asserts derived statuses. No UI
needed, same arrange/act/assert style as `test/test_AchievementManager.gd`. Cover at least: every
quest starts `OPEN`; unlocking the backing achievement flips it to `COMPLETED`;
`AchievementManager.reset()` returns everything to the start state; every `achievement_id` in
`QUESTS` actually exists in `AchievementManager.ACHIEVEMENTS` (guards against typos after a rename).

### Phase 5 — Input action

Add to the `[input]` section of `project.godot`, next to `pause_menu`:

```
quest_log={
"deadzone": 0.2,
"events": [ ... physical_keycode 4194332 (F1) ... ]
}
```

Desktop-only export, so `F1` needs no fallback binding.

### Phase 6 — `QuestLogGui`

`gui/quest_log_gui.tscn` / `.gd`, styled like `achievement_popup.tscn`, added to the same HUD layer.

Follow the `PauseGui` pattern ([gui/pause_gui.gd](gui/pause_gui.gd)):

```gdscript
func _process(_delta) -> void:
	if GameSession.quiz_dialog_displayed:
		_hide()
		return
	if Input.is_action_just_pressed("quest_log"):
		_toggle()
```

- Pause the tree while open, like the pause menu — the player should not be attacked while reading.
- Quests are listed in `QUESTS` order, so the chain reads top to bottom.
- One row per quest: status icon, title, hint, and either a checkbox or `current / target` when
  `target > 1`.
- `COMPLETED` rows keep the title but drop the hint and are visually ticked off.
- Rebuild the rows on `AchievementManager.achievement_unlocked` so the log is live while open.
- Reuse `NumberFormat` for the counters, as `AchievementPopup` does.
- Header makes the scope explicit: "Quests — aktueller Lauf".

### Phase 7 — Polish

- Show a short "Quest abgeschlossen" line in `AchievementPopup` when the unlocked achievement backs
  a quest. The popup already appends the bonus text, so this is one extra string.
- Hint the key once at the start of a run ("F1 — Questlog").

## Open questions

- Should quest 2 ("Ab in den Nether") use `nether_1`, which unlocks merely by entering? It makes the
  chain readable but is trivially completed. Alternative: fold it into quest 3's hint.
- Does the dungeon quest exist in every world type? `register_locations()` is only called from
  [classic/world_level.gd](classic/world_level.gd) — confirm the procedural worlds reach it, or the
  quest can never be completed there.
- Revisit `LOCKED` after playtesting: if seven open quests overwhelm younger players, it can be
  added on top of the derived status without touching stored data.
- **Playtest:** eyes come from loot drops, so "12 eyes" is a materially harder bar than the old
  "10 Enderman kills". Check that a normal run can still reach the End.
