# Feature: Companion Redesign (decouple companions from level scenes)

## Goal

Remove the coupling between a character's companions and the node layout of each world
scene. Today a companion's identity is its `NodePath`, which forces every level
(`main`, `nether`, `end`, `proc_gen_world`) to contain the same pre-placed `Wolf` nodes —
hidden outside the map borders — just so the saved paths resolve.

After this change:

- `Character.companions` holds **live `Companion` nodes**, owned by the character and
  surviving scene changes.
- Scene paths are a pure **serialization detail**, written only by `SaveManager`.
- `nether.tscn`, `end.tscn` and `proc_gen_world.tscn` contain **no companion nodes**.
- `damage_applied` / `set_damage_applied()` disappear.
- The "max 2 wolves" rule is **dropped** (explicit decision — see Out of scope).

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

## Target design

`Character` owns an `Array[Companion]` of real nodes:

- The node reports its own damage (`companion.damage`), so no catalog, no registry and no
  `root` parameter are needed.
- The node knows its own scene via the built-in `Node.scene_file_path`, so saving needs no
  id mapping.
- Companions are instantiated **once** — by `SaveManager` on load, or by pickup — and are
  re-parented into each level's `Companions` node on `_ready`, then detached again on
  `_exit_tree` so the scene change does not free them.

## Implementation steps

### 1. `companions/companion.gd` — move `damage` to the base class

`Array[Companion]` requires `damage` to type-check on `Companion`, not `Wolf`:

```gdscript
@export var damage: int = 0
```

The concrete value stays authored in `wolf.tscn`. No other behavioral change; keep
`execute()`, `start_following()` and the `is_following` guard as they are.

### 2. `companions/wolf.gd` — delete the pickup bookkeeping

```gdscript
class_name Wolf
extends Companion


func execute() -> void:
	Sound.play(Sound.dog_bark)
```

`damage_applied`, `set_damage_applied()` and the `add_companion(str(get_path()))` call are
removed — registration moves to `Main`, and a spawned follower is never a pickup.

Move the `@export var damage` line out of this file (now inherited from `Companion`), and
verify `wolf.tscn` still carries the authored value after the property moves to the parent
script.

### 3. `characters/character.gd` — hold nodes, expose paths

```gdscript
var companions: Array[Companion] = []


func get_total_damage() -> int:
	var total = get_damage()
	for companion in companions:
		total += companion.damage
	return total


func add_companion(companion: Companion) -> void:
	companions.append(companion)
	weapon_damage_changed.emit()
	SaveManager.save_character(self)


func get_companion_scene_paths() -> Array[String]:
	var paths: Array[String] = []
	for companion in companions:
		paths.append(companion.scene_file_path)
	return paths


func free_companions() -> void:
	for companion in companions:
		if is_instance_valid(companion) and not companion.is_inside_tree():
			companion.free()
	companions.clear()
```

Notes:

- `get_total_damage()` loses its `root` parameter.
- The old `if companion_path not in companions` guard is gone — duplicates are now
  expected, since two wolves share one scene path.
- `load_state()`'s last parameter changes from `Array[String]` to `Array[Companion]`.

### 4. `characters/character_manager.gd` — drop the `root` argument

```gdscript
func get_total_damage() -> int:
	return current.get_total_damage()
```

Call `current.free_companions()` before replacing `current` with a different character, so
orphan nodes are not leaked.

### 5. `classic/save_manager.gd` — convert at the boundary

On save:

```gdscript
"companions": character.get_companion_scene_paths(),
```

On load, instantiate immediately so the character owns real nodes before any level exists:

```gdscript
var companions: Array[Companion] = []
for path in _sanitize_string_array(data.get("companions", [])):
	if ResourceLoader.exists(path):
		companions.append(load(path).instantiate())
```

Entries that are not valid `res://` paths (old saves contain
`/root/Main/Companions/Wolf`) are skipped by the `ResourceLoader.exists()` check. Decide
whether to silently drop them or remap them to `res://companions/wolf.tscn` to preserve
existing players' wolves.

### 6. `classic/main.gd` — adopt instead of look up

```gdscript
func _setup_companions() -> void:
	for i in CharacterManager.current.companions.size():
		var companion := CharacterManager.current.companions[i]
		companions_root.add_child(companion)
		companion.global_position = player.global_position + Vector2(60.0 + i * 40.0, 0.0)
		companion.start_following(player)


func _on_companion_picked_up(companion: Companion) -> void:
	CharacterManager.current.add_companion(companion)
	companion.execute()
	companion.start_following(player)


func _exit_tree() -> void:
	for companion in CharacterManager.current.companions:
		if companion.get_parent() == companions_root:
			companions_root.remove_child(companion)
```

`_exit_tree()` is essential: without it, `change_scene_to_*` frees the level tree including
the companions, leaving `Character.companions` full of dangling references.

`_setup_signals()` keeps connecting `companion_picked_up` for the `Companions` children
present in the scene file — in `main.tscn` those are the two pickups. Adopted followers
have `is_following == true`, so `Companion._on_body_entered` already ignores them.

### 7. Scene changes

- `classic/nether.tscn`, `classic/end.tscn`, `procedural/proc_gen_world.tscn`: delete the
  `Wolf` and `Wolf2` instances; keep the empty `Companions` node (`main.gd` relies on
  `$Companions`).
- `classic/main.tscn`: keep `Wolf` and `Wolf2` as the in-world pickups, now inside the map.
- `companions/wolf.tscn`: confirm `damage` is still set after step 1.

### 8. Tests

- `test/test_SaveManager.gd`: the round-trip currently passes
  `["/root/Main/Companions/Wolf1"]` into `load_state()`. Update it to build an
  `Array[Companion]` (instantiate `wolf.tscn`, free it at teardown) and assert the saved
  JSON contains `res://companions/wolf.tscn`.
- `test/test_character_create_dialog.gd`: `companions.size() == 0` still holds.
- Add a test for `get_total_damage()` summing base weapon damage plus companion damage
  without any level scene loaded.

### 9. `gui/character_widget.gd`

`companions.size()` still gives the wolf count, so the label keeps working. Note that
`CharacterManager.get_total_damage()` now returns the **correct** value in the menu —
previously the node-path lookup failed outside a level and silently contributed 0.

## Out of scope / accepted consequences

- **The "max 2 wolves" cap is dropped.** Replaying `main` lets the player collect the two
  placed wolves again, so the pack and the damage bonus grow without bound. If the cap is
  wanted later, add `@export var max_count: int` to `Companion` and guard `add_companion()`
  with a count over `scene_file_path`.
- **Node lifetime becomes `Character`'s responsibility.** Companions live outside the tree
  between levels and are not garbage-collected; `free_companions()` must be called when a
  character is discarded.
- Companion positions are not persisted — they are re-seeded next to the player on every
  level load, as today.

## Verification checklist

- [ ] Fresh character: 0 wolves, pick up both in `main`, both follow.
- [ ] Travel to `nether` / `end` / `proc_gen_world`: both wolves appear next to the player
      although the scenes contain no wolf nodes.
- [ ] Damage shown in `PlayerStatsSheet` includes the companion bonus in every level.
- [ ] Damage shown in `CharacterWidget` (menu, no level loaded) includes the bonus.
- [ ] Quit and restart: wolves are restored from the save file and still follow.
- [ ] Repeated scene changes do not produce "previously freed object" errors.
- [ ] Old save file with node-path entries loads without crashing.
