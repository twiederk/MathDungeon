# Feature: Location Cleared ("Dungeon Clear")

## Goal

When the player has defeated **all enemies of a location**, an achievement is unlocked
(popup message + sound + badge).

Locations:

| Location id      | Level                  | Enemies                                           |
| ---------------- | ---------------------- | ------------------------------------------------- |
| `woodland_mansion` | `classic/overworld.tscn` | Vindicator (patrolling), Evoker, (Shooting) Pillager |
| `nether_fortress`  | `classic/nether.tscn`    | manually selected enemies                         |
| `dungeon_0` … `dungeon_3` | `procedural/proc_gen_world.tscn` | generated enemies per dungeon         |

The End is deliberately excluded: it only contains the Enderdragon and the game ends
right after defeating it.

Popup, sound and badge display already exist and only listen to the
`AchievementManager.achievement_unlocked` signal — so **no** new UI code is needed.

## Design decisions

1. **`Enemy` gets an exported `location` field** of type `String`. No Godot group
   mechanism, no extra location nodes. For Overworld/Nether the field is set in the
   editor, in `ProcGenWorld` it is set in code while placing the enemies. `String` keeps
   it consistent with `Achievement.type`, the `ACHIEVEMENTS` keys and the `progress`
   dictionary keys — mixing `String` and `StringName` keys in the same dictionary is a
   subtle source of failed lookups.
2. **Counter based, not "is the group empty?"**: `queue_free()` is deferred, so a check
   right after a kill would still count the enemy. Instead `WorldLevel` registers the
   number of enemies per location on load and every victory decrements it.
3. **Registration happens in exactly one place**: `WorldLevel._ready()`.
   `ProcGenWorld._ready()` builds the world *before* `super._ready()`, so the enemies
   already exist. Clear first, then register — so re-entering a level does not
   accumulate the counters.
4. **Location id == achievement type**, each with `target = 1`. This makes the feature
   fit the existing `progress` / `_check_progress_achievements` scheme without a special
   case, and every dungeon gets its own achievement.
5. **No repeat reward**: like all existing achievements, each one unlocks only once per
   session (the `unlocked_achievements` guard stays unchanged).

## Implementation steps

### 1. ✅ `enemies/enemy.gd`

```gdscript
@export var location: String = ""
```

`_ready()` stays unchanged.

### 2. ✅ `enemies/patrolling_enemy.gd`

For patrolling enemies the actual `Enemy` is nested under `PathFollow2D/Enemy` and is
not reachable in the inspector of the Overworld level. Therefore the `Path2D` wrapper
gets its own exported field and forwards it:

```gdscript
@export var location: String = ""

func _ready() -> void:
	path_follow.progress_ratio = randf_range(0, 1)
	enemy.location = location
```

Order is not a problem: `_ready()` of the children runs before `WorldLevel._ready()`.

### 3. ✅ `classic/achievement_manager.gd`

- New achievements (each `target = 1`, `type` == location id). Titles and descriptions
  stay German because they are in-game text:

  ```gdscript
  "woodland_mansion": Achievement.new("Waldanwesen erobert!", "Besiege alle Bewohner des Waldanwesens", 1, "woodland_mansion", "woodland_mansion.png"),
  "nether_fortress":  Achievement.new("Festung gesäubert!", "Besiege alle Gegner der Nether-Festung", 1, "nether_fortress", "nether_fortress.png"),
  "dungeon_0": Achievement.new("Dungeon 1 gesäubert!", "Besiege alle Gegner im ersten Dungeon", 1, "dungeon_0", "dungeon_0.png"),
  "dungeon_1": ... "dungeon_2": ... "dungeon_3": ...
  ```

- New field `var _locations: Dictionary = {}` (location id → remaining enemies).

- Registration:

  ```gdscript
  func clear_locations() -> void:
  	_locations.clear()


  func register_locations(enemies: Array) -> void:
  	for enemy in enemies:
  		if enemy is not Enemy or enemy.location == "":
  			continue
  		_locations[enemy.location] = _locations.get(enemy.location, 0) + 1
  ```

- `track_enemy_defeat` receives the `Enemy` instead of the name and additionally
  decrements the location counter:

  ```gdscript
  func track_enemy_defeat(enemy: Enemy) -> void:
  	var enemy_name := enemy.stats.name
  	... # existing Enderman/Enderdragon counters

  	var id: String = enemy.location
  	if not _locations.has(id):
  		return
  	_locations[id] -= 1
  	if _locations[id] > 0:
  		return
  	_locations.erase(id)
  	progress[id] = progress.get(id, 0) + 1
  	_check_progress_achievements(id)
  ```

  Important: `progress` is initialized with fixed keys, so use `progress.get(type, 0)`
  instead of `progress[type]` everywhere — including in `_check_progress_achievements()`.

- `reset()` additionally clears `_locations` and removes the location progress entries.

### 4. ✅ `classic/world_level.gd`

In `_ready()`, before/after `_setup_signals()`:

```gdscript
AchievementManager.clear_locations()
AchievementManager.register_locations(enemies_root.find_children("", "Enemy", true, false))
```

`get_children()` would not be enough: patrolling enemies forward their `location` to the
inner `Enemy`, but the wrapper itself is a `Path2D` and would be skipped. `find_children`
with `recursive = true` and `owned = false` returns exactly the set of nodes that can
actually be defeated. `owned = false` is mandatory, otherwise nodes inside instanced
subscenes are missing.

### 5. ✅ `procedural/dungeon.gd` + `dungeon_generator.gd` + `proc_gen_world.gd`

- `Dungeon` gets an `id: String` field (extra `_init` parameter or assigned
  afterwards — assigning afterwards keeps `DungeonGenerator` free of numbering logic).
- `ProcGenWorld.generate_world()` assigns `dungeon.id = "dungeon_%d" % index` while
  looping over the offsets.
- `ProcGenWorld._place_enemies()` sets `enemy.location = dungeon.id` before `add_child`.

No registration inside `ProcGenWorld` — that is done by `WorldLevel._ready()`, which
runs afterwards via `super._ready()`.

### 6. ✅ `quiz/quiz_dialog.gd`

Adjust the call: `AchievementManager.track_enemy_defeat(enemy)` instead of
`track_enemy_defeat(enemy.stats.name)`. Only call site.

### 7. ✅ Scenes / editor work

- `classic/overworld.tscn`: set `location = woodland_mansion` on the root `Path2D` of
  Vindicator 1–4 (instances of `patrolling_vindicator.tscn`); set it on the `Enemy` node
  for Evoker and (Shooting) Pillager.
- `classic/nether.tscn`: `location = nether_fortress` on the chosen enemies.
- `classic/end.tscn`: nothing to do.

### 8. Badges

`gui/achievement_badges.gd` loads `gui/badges/<badge_graphic>`; the fallback points to
`badge_1000.png`, which does not exist. There is no artwork for the 6 new achievements
yet, so they all use the existing `score_1000.png` for now.

### 9. Tests (`test/`, GUT)

New: `test/test_AchievementManager.gd`

- `test_register_locations_counts_enemies_per_location`
- `test_register_locations_ignores_enemies_without_location`
- `test_clear_locations_resets_counts` (no accumulation on re-registration)
- `test_last_defeat_unlocks_achievement` (assert the `achievement_unlocked` signal)
- `test_defeat_before_last_does_not_unlock`
- `test_defeat_of_unregistered_location_is_ignored`

`register_locations` takes an `Array`, so it can be tested without a SceneTree.

Existing tests: check whether the `Dungeon.id` change breaks the signature used in
`test/test_DungeonGenerator.gd`.

## Open points / deliberately out of scope

- **Loot drop for patrolling enemies** does not work (`PatrollingEnemy` does not forward
  `defeated`, and `WorldLevel._setup_signals()` only looks at direct children). This is
  **not** fixed in this step.
- Achievements are not persisted (`SaveManager` only stores the character) — stays
  unchanged, the reset happens via `gui/start_menu.gd`.
