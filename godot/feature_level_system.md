# Feature: Level System (Schwierigkeitsgrad)

## Goal

The gamer can choose between two difficulty levels before starting a run:

- **NORMAL** — the game behaves exactly as it does today.
- **HARD** — enemies use stronger values (more hit points, more damage, more armor, more/harder
  arithmetic types, higher `max_number`) and most of them get a `time_limit`.

The choice is made in the start menu with a single toggle button and is stored in `PlayerStats`.

## Decisions

| Topic | Decision |
|---|---|
| Selection UI | One `Button` in `start_menu.tscn` that toggles its own caption |
| Captions | `"Schwierigkeitsgrad: normal"` / `"Schwierigkeitsgrad: schwer"` |
| Where is the level stored | `PlayerStats.difficulty_level` (autoload, already global) |
| Enum location | `PlayerStats.DifficultyLevel { NORMAL, HARD }` |
| Where are hard values stored | New `hard_*` exports on `EnemyStats` (same resource, no second `.tres` set) |
| Unset hard value | Falls back to the normal value (sentinel-based, see below) |
| Score | `EnemyStats.get_score()` uses the values of the active difficulty |
| Persistence | Not persisted; resets to `NORMAL` on every application start |
| Highscore list | Out of scope for this feature (see "Out of scope") |

### Why one resource instead of two resource sets

Every enemy scene has an `@export var stats: EnemyStats` wired to one concrete `.tres`. Adding a
second set would require touching all `*.tscn` files and a runtime switch in every enemy. Keeping
both value sets in the same resource means **only `EnemyStats` knows about the difficulty**, and all
consumers simply call accessor methods.

### Fallback sentinels

Not every enemy needs a distinct hard value. Unset hard values must fall back to the normal value,
so the `.tres` files only need to be edited where the hard mode actually differs.

| Property | "unset" sentinel | Reason |
|---|---|---|
| `hard_max_hit_points` | `-1` | 0 hit points is not a valid enemy |
| `hard_damage` | `-1` | 0 damage is theoretically valid |
| `hard_armor` | `-1` | 0 armor is valid (default) |
| `hard_arithmetic` | empty array | an enemy always needs at least one arithmetic type |
| `hard_max_number` | `-1` | 0 is not a useful maximum |
| `hard_time_limit` | `0` | `-1` already means "no time limit" and must stay selectable |

## Current state

- `EnemyStats` (`enemies/enemy_stats.gd`) exposes `name`, `max_hit_points`, `damage`, `armor`,
  `arithmetic`, `max_number`, `time_limit` and computes `get_score()` from them.
- Consumers read the fields **directly**:
  - [enemies/enemy.gd](enemies/enemy.gd) — `stats.max_hit_points`, `stats.time_limit`, `stats.armor`
  - [enemies/projectile.gd](enemies/projectile.gd) — `projectile_stats.max_hit_points`
  - [quiz/quiz_dialog.gd](quiz/quiz_dialog.gd) — `stats.max_hit_points`, `stats.damage`,
    `stats.armor`, `stats.time_limit`, `stats.arithmetic`, `stats.max_number`
- `PlayerStats` (`classic/player_stats.gd`, autoload) holds only per-run state (`score`,
  `eyes_of_ender`) plus `reset()`.
- `start_menu.gd` / `start_menu.tscn` contain five buttons in
  `CenterContainer/VBoxContainer`, each connected via a `pressed` signal.

## Phases

Each phase is independently shippable.

### Phase 1 — `DifficultyLevel` in `PlayerStats`

In [classic/player_stats.gd](classic/player_stats.gd):

```gdscript
enum DifficultyLevel {
	NORMAL,
	HARD
}

signal difficulty_level_changed

var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL:
	set(value):
		difficulty_level = value
		difficulty_level_changed.emit()


func is_hard() -> bool:
	return difficulty_level == DifficultyLevel.HARD


func toggle_difficulty_level() -> void:
	difficulty_level = DifficultyLevel.NORMAL if is_hard() else DifficultyLevel.HARD
```

Important: `reset()` must **not** reset `difficulty_level` — it is a setting of the session, not
per-run state. `reset()` keeps resetting `score` and `eyes_of_ender` only.

The `difficulty_level_changed` signal is not strictly needed by the start menu (it sets the caption
itself), but it keeps the property consistent with the existing `score_changed` pattern and allows
a HUD to show the level later.

### Phase 2 — Hard values on `EnemyStats`

In [enemies/enemy_stats.gd](enemies/enemy_stats.gd) add the exports right after the existing ones:

```gdscript
@export_group("Hard")
@export var hard_max_hit_points: int = -1
@export var hard_damage: int = -1
@export var hard_armor: int = -1
@export var hard_arithmetic: Array[ArithmeticType] = []
@export var hard_max_number: int = -1
@export var hard_time_limit: int = 0
```

Add accessors that resolve the active difficulty. These are the **only** API the rest of the game
should use from now on:

```gdscript
func get_max_hit_points() -> int:
	if _use_hard() and hard_max_hit_points >= 0:
		return hard_max_hit_points
	return max_hit_points


func get_damage() -> int:
	if _use_hard() and hard_damage >= 0:
		return hard_damage
	return damage


func get_armor() -> int:
	if _use_hard() and hard_armor >= 0:
		return hard_armor
	return armor


func get_arithmetic() -> Array[ArithmeticType]:
	if _use_hard() and not hard_arithmetic.is_empty():
		return hard_arithmetic
	return arithmetic


func get_max_number() -> int:
	if _use_hard() and hard_max_number >= 0:
		return hard_max_number
	return max_number


func get_time_limit() -> int:
	if _use_hard() and hard_time_limit != 0:
		return hard_time_limit
	return time_limit


func has_time_limit() -> bool:
	return get_time_limit() != -1


func _use_hard() -> bool:
	return PlayerStats.is_hard()
```

Note on testability: `EnemyStats` now depends on the `PlayerStats` autoload. Unit tests
(`test/test_EnemyStats.gd`) can set `PlayerStats.difficulty_level` in `before_each()` /
`after_each()` and must reset it to `NORMAL` afterwards so tests stay independent.

### Phase 3 — `get_score()` uses the active difficulty

Rewrite `get_score()` so the formula stays unchanged but reads through the accessors:

```gdscript
func get_score() -> int:
	var score: int = 0

	score += get_max_hit_points() * 2
	score += get_damage() * 2
	score += get_arithmetic().size() * 2
	score += get_armor() * 4

	var limit := get_time_limit()
	if limit != -1:
		score += (60 - limit) * 4

	return score
```

Consequence: in HARD mode a defeated enemy is worth more points, because the hard values are higher
and a shorter/added time limit increases the time bonus. No extra multiplier is introduced — the
existing formula already rewards the harder values.

Existing tests in [test/test_EnemyStats.gd](test/test_EnemyStats.gd) stay valid for NORMAL. Add
parallel tests for HARD once the `.tres` files of Phase 5 are filled in.

### Phase 4 — Use the accessors everywhere

Replace every direct field read with the accessor:

| File | Change |
|---|---|
| [enemies/enemy.gd](enemies/enemy.gd) | `hit_points = stats.get_max_hit_points()`; `has_time_limit()` delegates to `stats.has_time_limit()`; `hurt()` uses `stats.get_armor()` |
| [enemies/projectile.gd](enemies/projectile.gd) | `enemy.hit_points = projectile_stats.get_max_hit_points()` |
| [quiz/quiz_dialog.gd](quiz/quiz_dialog.gd) | `_setup_enemy_stats_sheet()` → `get_max_hit_points()`, `get_damage()`, `get_armor()`; `_start_timers()` → `get_time_limit()`; `_create_exercise()` → `get_arithmetic()` and `get_max_number()`; `_answer_incorrect()` and `_answer_timeout()` → `get_damage()`; `_on_answer_timer_timeout()` → `get_time_limit()` |

`stats.name` stays a direct read — the name does not depend on the difficulty.

Checklist to verify nothing is missed: after this phase a project-wide search for
`stats.max_hit_points`, `stats.damage`, `stats.armor`, `stats.arithmetic`, `stats.max_number` and
`stats.time_limit` must only find hits inside `enemy_stats.gd` itself and inside `.tres` files.

Caution: `Enemy._ready()` reads `get_max_hit_points()` once. Because the difficulty is chosen in the
start menu *before* the world scene loads, this is safe. Changing the difficulty mid-run is
explicitly **not** supported.

### Phase 5 — Fill in the hard values in the `.tres` files

All resources under `enemies/*_stats.tres` get their hard values. Guidelines:

- Every enemy that currently has `time_limit = -1` gets a `hard_time_limit` (roughly 30 s for weak
  enemies, down to 10 s for bosses).
- Enemies that already have a time limit get a shorter `hard_time_limit`.
- `hard_max_hit_points` ≈ 1.5× the normal value, `hard_damage` ≈ +1, `hard_max_number` ≈ 2×.
- `hard_arithmetic` only where the hard mode should add operations (e.g. adding
  `MULTIPLICATION`/`DIVISION` to an enemy that only does `ADDITION`).
- Leave a property out of the `.tres` entirely when the normal value should be kept.

Proposed starting values (to be tuned by play-testing):

| Resource | hard_max_hit_points | hard_damage | hard_max_number | hard_time_limit |
|---|---|---|---|---|
| `zombie_stats` | 3 | – | 40 | 30 |
| `zombie_baby_stats` | – | – | 20 | 30 |
| `villager_stats` / `villager_zombie_stats` | 3 | – | – | 30 |
| `skeleton_stats` | 5 | 2 | – | 25 |
| `creeper_stats` | 6 | 2 | – | 25 |
| `spider_stats` | 8 | 2 | – | 20 |
| `drown_stats` | 5 | 2 | – | 25 |
| `pillager_stats` / `vindicator_stats` | 8 | 2 | – | 20 |
| `piglin_stats` | 12 | 3 | – | 20 |
| `piglin_zombie_stats` | 10 | 3 | – | 20 |
| `piglin_boss_stats` | 15 | 3 | – | 15 |
| `blaze_stats` | 9 | 3 | – | 15 |
| `ghast_stats` | 18 | 3 | – | 15 |
| `evoker_vex_stats` | 3 | 2 | – | 15 |
| `iron_golem_stats` | 18 | 3 | 2000 | 15 |
| `enderman_stats` | 15 | 3 | – | 10 |
| `enderdragon_stats` | 30 | 4 | – | 8 |
| `blaze_fireball_stats` / `fireball_stats` / `arrow_stats` | 3 | – | – | 10 |
| `pig_stats` | – | – | 10 | 30 |

### Phase 6 — Toggle button in the start menu

Add a `Button` named `DifficultyButton` to `CenterContainer/VBoxContainer` in
[gui/start_menu.tscn](gui/start_menu.tscn), placed **below `StartGenericButton`** (so the two start
buttons stay on top), with the initial text `"Schwierigkeitsgrad: normal"` and a `pressed`
connection to `_on_difficulty_button_pressed`.

In [gui/start_menu.gd](gui/start_menu.gd):

```gdscript
const DIFFICULTY_LABELS := {
	PlayerStats.DifficultyLevel.NORMAL: "Schwierigkeitsgrad: normal",
	PlayerStats.DifficultyLevel.HARD: "Schwierigkeitsgrad: schwer"
}

@onready var difficulty_button: Button = $CenterContainer/VBoxContainer/DifficultyButton


func _ready():
	character_widget.update_stats()
	_update_difficulty_button()
	start_button.grab_focus()


func _on_difficulty_button_pressed() -> void:
	PlayerStats.toggle_difficulty_level()
	_update_difficulty_button()


func _update_difficulty_button() -> void:
	difficulty_button.text = DIFFICULTY_LABELS[PlayerStats.difficulty_level]
```

`_update_difficulty_button()` is also called in `_ready()` so the caption is correct when the gamer
returns to the start menu after a run (the selection is kept).

### Phase 7 — Tests

Extend [test/test_EnemyStats.gd](test/test_EnemyStats.gd):

- `after_each()` resets `PlayerStats.difficulty_level = PlayerStats.DifficultyLevel.NORMAL`.
- Keep the existing NORMAL score tests unchanged (regression guard: hard values must not leak into
  normal mode).
- Add HARD score tests for at least `zombie_stats`, `spider_stats` and `enderdragon_stats`.
- Add fallback tests on a freshly constructed `EnemyStats.new()`: with no `hard_*` values set, all
  accessors must return the normal values in HARD mode, and `get_score()` must be identical in both
  modes.
- Add a test that `hard_time_limit == -1` really disables the time limit in HARD mode even when
  `time_limit` is set.

New `test/test_PlayerStats.gd`:

- default is `NORMAL`
- `toggle_difficulty_level()` switches `NORMAL → HARD → NORMAL`
- `difficulty_level_changed` is emitted
- `reset()` does not change `difficulty_level`

## Out of scope

- Persisting the difficulty in the save file / between application starts.
- Separating the highscore list per difficulty (currently one list; hard runs will simply score
  higher). A `difficulty` field in `HighscoreManager` would be the follow-up feature.
- Showing the current difficulty inside the running game (HUD / `stats_sheet`).
- Difficulty-dependent enemy spawning or map generation in `procedural/`.
- A third level ("leicht").
