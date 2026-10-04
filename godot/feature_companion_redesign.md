# Feature: Companion Redesign

## Goals

1. **Remove the coupling between a character's companions and the node layout of each world
   scene.** Today a companion's identity is its `NodePath`, which forces every level
   (`main`, `nether`, `end`, `proc_gen_world`) to contain the same pre-placed `Wolf` nodes —
   hidden outside the map borders — just so the saved paths resolve.

2. **Move `CharacterManager.get_total_damage()` into `Character.get_total_damage()` by
   removing the dependency on a root node.** The current signature
   `Character.get_total_damage(root: Node)` exists only so companion node paths can be
   resolved, and `CharacterManager` passes itself as `root`. A character must be able to
   report its total damage without any scene tree being involved.

## Current state

- `characters/character.gd`: `companions: Array[String]` stores absolute node paths
  (e.g. `/root/Main/Companions/Wolf`). `get_total_damage(root)` resolves each path via
  `root.get_node_or_null()` and sums `companion.damage`.
- `characters/character_manager.gd`: `get_total_damage()` passes the autoload itself as
  `root`, which works only because the stored paths are absolute.
- `companions/companion.gd` (`Companion`, extends `CharacterBody2D`): pickup + follow
  behavior, `execute()` hook, `is_following` guard in `_on_body_entered`.
- `companions/wolf.gd` (`Wolf`): `@export var damage`, plus `damage_applied` bookkeeping
  so an already-following wolf cannot re-register itself.
- `classic/main.gd`: `_setup_companions()` looks up saved paths in the current scene,
  repositions them next to the player, calls `start_following()` and `set_damage_applied()`.
- `classic/main.tscn`, `classic/nether.tscn`, `classic/end.tscn`,
  `procedural/proc_gen_world.tscn`: each has a `Companions` node with `Wolf` + `Wolf2`.
  Only `main.tscn`'s are reachable; the rest sit outside the map borders.
- `classic/save_manager.gd`: persists `character.companions` as a string array and
  restores it through `_sanitize_string_array()`.
- All levels extend `Main` (`Nether`, `End`, `ProcGenWorld`), so level-side logic only
  has to be written once.

## Phase 1 — record the companion type on pickup

Introduce a second, path-free list on `Character` that records *what* the player owns. It
runs **in parallel** with the existing `companions` path array, so this phase changes no
behavior and can be shipped on its own.

### 1.1 `characters/character.gd`

```gdscript
var companion_types: Array[String] = []


func add_companion_type(companion_type: String) -> void:
	companion_types.append(companion_type)
	weapon_damage_changed.emit()
	SaveManager.save_character(self)
```

Duplicates are allowed — two wolves produce `["Wolf", "Wolf"]`.

### 1.2 Obtaining the identifier

`node.get_script().get_global_name()` works on Godot 4.7 and yields `&"Wolf"`, but note:

- it returns a `StringName`, so wrap it in `String(...)` before appending to an
  `Array[String]`;
- it returns `&""` for any script without a `class_name`, which fails silently.

Alternatives, with the trade-off that matters for the later phases:

| Source | Value for the wolf | Can it re-create the companion? |
| --- | --- | --- |
| `get_script().get_global_name()` | `"Wolf"` | **No** — a class name cannot be instantiated from a string without walking `ProjectSettings.get_global_class_list()`, and that yields the *script* path, not the scene. |
| `get_script().get_path()` | `"res://companions/wolf.gd"` | No — script only, no sprite/collision/exports. |
| `scene_file_path` | `"res://companions/wolf.tscn"` | **Yes** — `load(path).instantiate()`. |
| `@export var companion_type: String` on `Companion` | author-defined | Only via an explicit lookup table. |

**Open decision:** if a later phase has to spawn companions in `nether` / `end` /
`proc_gen_world`, the stored string must be resolvable back to a `PackedScene`. In that
case `scene_file_path` is the better identifier, and `get_global_name()` is only suitable
for display and counting. Confirm the intent before phase 2.

### 1.3 `classic/main.gd`

Record the type where the pickup is already handled:

```gdscript
func _on_companion_picked_up(companion: Companion) -> void:
	CharacterManager.current.add_companion_type(String(companion.get_script().get_global_name()))
	companion.execute()
	if player:
		companion.start_following(player)
```

`Wolf.execute()` keeps its existing `add_companion(str(get_path()))` call for now; it is
removed in a later phase once nothing reads the path array any more.

### 1.4 `classic/save_manager.gd`

Persist the new array alongside the old one:

```gdscript
"companion_types": character.companion_types,
```

and restore it through the existing `_sanitize_string_array()` helper. `load_state()` gains
a trailing `a_companion_types: Array[String]` parameter. Saves written before this change
have no `companion_types` key, so the default `[]` applies — existing wolves are not
back-filled unless the load step derives them from the old path entries.

### 1.5 Verification

- [ ] Pick up both wolves in `main`: `companion_types == ["Wolf", "Wolf"]`.
- [ ] Restart the game: the array survives the save/load round-trip.
- [ ] Nothing else changes — damage, following and the stats sheet behave as before.

## Phase 2 — make `get_total_damage()` root-free

Rewrite the damage calculation to read `companion_types` instead of resolving node paths,
then delete the `CharacterManager` wrapper. This completes goal 2.

### 2.1 `characters/character.gd`

```gdscript
const WOLF_DAMAGE: int = 1


func get_total_damage() -> int:
	var total = get_damage()
	for companion_type in companion_types:
		if companion_type == "Wolf":
			total += WOLF_DAMAGE
	return total
```

The `root: Node` parameter is gone, together with the `get_node_or_null()` loop and the
`"damage" in companion` check. A `Character` can now report its damage with no scene tree
loaded at all.

`WOLF_DAMAGE` is `1`, matching the `damage = 1` authored on the root node of
`companions/wolf.tscn`. Keeping the two in sync is a known duplication; a later phase can
replace the hardcoded constant by reading the value back from the companion scene.

### 2.2 Unit test — `test/test_Character.gd`

The existing suite builds its fixture via
`character.load_state("Steve", "steve", 5, 5, 1, 0, [])`, so the new parameter from phase 1
has to be threaded through `before_each()`. Add cases covering the three interesting
states:

```gdscript
func test_get_total_damage_without_companions():
	# act
	var result = character.get_total_damage()

	# assert
	assert_eq(1, result, "Total damage equals the weapon damage when no companion is owned")


func test_get_total_damage_adds_one_per_wolf():
	# arrange
	character.add_companion_type("Wolf")
	character.add_companion_type("Wolf")

	# act
	var result = character.get_total_damage()

	# assert
	assert_eq(3, result, "Each wolf adds one damage on top of the weapon damage")


func test_get_total_damage_ignores_unknown_companion_types():
	# arrange
	character.add_companion_type("Allay")

	# act
	var result = character.get_total_damage()

	# assert
	assert_eq(1, result, "Unknown companion types contribute no damage")
```

The decisive property: **no scene is instantiated and no node is required**, which is
exactly what was impossible before.

Note that `add_companion_type()` calls `SaveManager.save_character()`. If that writes to
disk during the test run, either set `companion_types` directly in the arrange step or
point `SaveManager` at a temp path in `before_each()`.

### 2.3 Replace every call site

| File | Current call | New call |
| --- | --- | --- |
| `classic/main.gd` (`_setup_character_stats`) | `CharacterManager.get_total_damage()` | `CharacterManager.current.get_total_damage()` |
| `classic/main.gd` (`_on_player_stats_changed`) | `CharacterManager.get_total_damage()` | `CharacterManager.current.get_total_damage()` |
| `gui/character_widget.gd` (`update_stats`) | `CharacterManager.get_total_damage()` | `CharacterManager.current.get_total_damage()` |
| `quiz/quiz_dialog.gd` (`enemy.hurt(...)`) | `CharacterManager.get_total_damage()` | `CharacterManager.current.get_total_damage()` |

Both `main.gd` lines already read `hit_points`, `max_hit_points` and `armor` through
`CharacterManager.current`, so this makes the call consistent with its neighbours.

### 2.4 Remove the wrapper

Delete from `characters/character_manager.gd`:

```gdscript
func get_total_damage() -> int:
	return current.get_total_damage(self)
```

With it goes the last reason for the autoload to be passed around as a node path root.

### 2.5 Verification

- [ ] `test/test_Character.gd` passes, including the three new cases.
- [ ] A grep for `CharacterManager.get_total_damage` returns no hits.
- [ ] In-game stats sheet shows weapon damage + 1 per wolf in every level.
- [ ] `CharacterWidget` in the menu now also shows the companion bonus — previously it
      silently showed 0 extra, because the absolute node paths never resolved there.
- [ ] Quiz damage dealt to enemies matches the stats sheet.

## Phase 3 — reuse or spawn companions per level

`companion_types` is the list of companions that *must* be present in the current level.
`companions_root` holds whatever the level scene happens to provide. Phase 3 reconciles the
two: **reuse a matching node if the level already has one, otherwise instantiate the scene.**
This completes goal 1 and makes the companion nodes in `nether`, `end` and
`proc_gen_world` obsolete.

### 3.1 `classic/main.gd` — reconcile instead of look up

```gdscript
func _setup_companions() -> void:
	var used: Array[Node] = []
	var companion_types := CharacterManager.current.companion_types

	for i in companion_types.size():
		var companion := _claim_companion(companion_types[i], used)
		if companion == null:
			continue
		used.append(companion)
		companion.global_position = player.global_position + Vector2(60.0 + i * 40.0, 0.0)
		companion.start_following(player)


func _claim_companion(companion_type: String, used: Array[Node]) -> Companion:
	for child in companions_root.get_children():
		if child in used or not child is Companion:
			continue
		if String(child.get_script().get_global_name()) == companion_type:
			return child

	var companion := _instantiate_companion(companion_type)
	if companion:
		companions_root.add_child(companion)
	return companion


func _instantiate_companion(companion_type: String) -> Companion:
	var scene_path := "res://companions/%s.tscn" % companion_type.to_snake_case()
	if not ResourceLoader.exists(scene_path):
		push_warning("Unknown companion type: " + companion_type)
		return null
	return load(scene_path).instantiate()
```

Three details that make this correct:

- **`used` prevents double-claiming.** With `["Wolf", "Wolf"]` and `Wolf` + `Wolf2` in
  `main.tscn`, the first entry claims `Wolf` and the second must fall through to `Wolf2`
  rather than matching `Wolf` again.
- **Unclaimed children stay pickups.** Owning one wolf claims one node; the other keeps its
  `companion_picked_up` connection from `_setup_signals()` and remains collectable. Owning
  both leaves nothing collectable, which reproduces today's "can't pick them up again"
  behavior without any node-path bookkeeping.
- **Spawned nodes are never pickups.** They are added after `_setup_signals()` has run, so
  their signal is unconnected, and `start_following()` sets `is_following = true`, which
  the guard in `Companion._on_body_entered` already respects.

### 3.2 The name-to-path convention

`get_global_name()` yields `"Wolf"` but the file is `companions/wolf.tscn`, so a plain
concatenation of `"res://companions/" + companion_type + ".tscn"` does **not** resolve.
`to_snake_case()` bridges the gap and also handles future multi-word types:

| `class_name` | `to_snake_case()` | Expected scene |
| --- | --- | --- |
| `Wolf` | `wolf` | `res://companions/wolf.tscn` |
| `Allay` | `allay` | `res://companions/allay.tscn` |
| `IronGolem` | `iron_golem` | `res://companions/iron_golem.tscn` |

This makes the convention load-bearing: **every companion scene must live in
`res://companions/` and be named after the snake_case form of its `class_name`.** The
`ResourceLoader.exists()` guard turns a violation into a warning instead of a crash, which
also covers stale entries in old save files.

### 3.3 Scene cleanup

- `classic/nether.tscn`, `classic/end.tscn`, `procedural/proc_gen_world.tscn`: **delete the
  `Wolf` and `Wolf2` instances.** Keep the empty `Companions` node — `main.gd` still
  resolves `$Companions`, and spawned companions are parented to it.
- `classic/main.tscn`: unchanged. Its two wolves stay as the in-world pickups and are now
  claimed by `_setup_companions()` when already owned.

### 3.4 Verification

- [ ] 0 wolves owned, enter `main`: both wolves sit in the world and can be picked up.
- [ ] 1 wolf owned, enter `main`: one wolf follows the player, the other is still
      collectable.
- [ ] 2 wolves owned, enter `main`: both follow, nothing is collectable, and no third wolf
      appears.
- [ ] Enter `nether` / `end` / `proc_gen_world` with 2 wolves: both are spawned next to the
      player although the scenes contain no companion nodes.
- [ ] Enter those levels with 0 wolves: no companions appear and no warning is logged.
- [ ] A stale or misspelled entry in `companion_types` logs the warning and is skipped
      without crashing.

## Phase 4 — remove the legacy path mechanism

After phase 3 nothing reads the node-path array any more. This phase deletes it and the
bookkeeping that only existed to support it.

### 4.1 `characters/character.gd`

Remove:

```gdscript
var companions: Array[String] = []


func add_companion(companion_path: String) -> void:
	if companion_path not in companions:
		companions.append(companion_path)
		weapon_damage_changed.emit()
		SaveManager.save_character(self)
```

`load_state()` drops its `a_companions` parameter and the `companions = a_companions`
assignment, keeping only `a_companion_types` from phase 1. `companion_types` becomes the
single source of truth.

### 4.2 `classic/save_manager.gd`

Remove the `"companions": character.companions,` entry from the `save_character()`
dictionary and the matching
`_sanitize_string_array(data.get("companions", []))` argument in `_character_from_data()`.
`_sanitize_string_array()` itself stays — it is still used for `companion_types`.

Old save files keep their now-unread `companions` key; `JSON.parse_string()` ignores it and
the next `save_character()` drops it. No migration code is required, but note that wolves
earned before phase 1 are **not** carried over — those players restart with an empty
companion list unless a one-off back-fill is added in `_character_from_data()`.

### 4.3 `companions/wolf.gd`

Reduces to the sound hook:

```gdscript
class_name Wolf
extends Companion


func execute() -> void:
	Sound.play(Sound.dog_bark)
```

Gone: `@export var damage`, `var damage_applied`, `set_damage_applied()` and the
`CharacterManager.current.add_companion(str(get_path()))` call. The damage value now lives
in `Character.WOLF_DAMAGE` (phase 2), and the "already collected" guard is covered by
`is_following` plus the claiming logic from phase 3.

Note `damage = 1` remains written in `companions/wolf.tscn` as an orphaned property for a
no-longer-existing export; re-save the scene in the editor to drop it cleanly.

### 4.4 `classic/main.gd`

`_setup_companions()` no longer needs the `has_method("set_damage_applied")` branch, and
`_on_companion_picked_up()` keeps only the `companion_types` registration from phase 1:

```gdscript
func _on_companion_picked_up(companion: Companion) -> void:
	CharacterManager.current.add_companion_type(String(companion.get_script().get_global_name()))
	companion.execute()
	if player:
		companion.start_following(player)
```

### 4.5 Dependent call sites

| File | Change |
| --- | --- |
| `gui/character_widget.gd` | `character.companions.size()` → `character.companion_types.size()` |
| `test/test_SaveManager.gd` | the fixture passes `["/root/Main/Companions/Wolf1"]` into `load_state()`; switch it to `["Wolf"]` and assert on the `companion_types` key |
| `test/test_character_create_dialog.gd` | `companions.size() == 0` → `companion_types.size() == 0` |
| `test/test_Character.gd` | `before_each()`'s `load_state(...)` loses the old array argument |

A grep for `\.companions\b` should return no hits once this phase is done.

### 4.6 Verification

- [ ] Full GUT suite passes.
- [ ] Picking up a wolf still plays the bark and increases the damage on the stats sheet.
- [ ] Save, quit, restart: the wolves return in `main` and in every other level.
- [ ] Neither `Character` nor `SaveManager` mentions node paths any more.
