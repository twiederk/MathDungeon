# Feature: Nether return path & stable world seed via GameSession

## Problem

1. `NetherPortal` in `classic/nether.tscn` has a hardcoded `dungeon_path = "res://classic/overworld.tscn"`.
   When the Nether is entered from `procedural/proc_gen_world.tscn`, leaving the Nether must return to
   `res://procedural/proc_gen_world.tscn` instead.
2. `ProcGenWorld` generates a new random seed in `_ready()`. Returning from the Nether therefore produces a
   completely different world. Within one game session the same seed must be reused.

Both pieces of state belong to the session, so `GameSession` (autoload) is the right owner.

## Decisions (agreed)

- Only the Nether portal uses the session return path for now; the End portal stays unchanged.
- The seed is generated once per game session and only regenerated on `GameSession.reset()`.
- The seed is kept in memory only; it is **not** persisted through `SaveManager`.

## Design

### GameSession additions

```gdscript
const DEFAULT_OVERWORLD_PATH := "res://classic/overworld.tscn"

var overworld_path: String = DEFAULT_OVERWORLD_PATH
var world_seed: int = 0   # 0 == "not generated yet"
```

- `reset()` sets `overworld_path = DEFAULT_OVERWORLD_PATH` and `world_seed = 0`.
- `func set_overworld_path(path: String) -> void` – stores the scene the Nether should return to.
- `func get_or_create_world_seed() -> int` – returns `world_seed`; if it is `0`, generates a new
  non-zero `randi()` value, stores it and returns it.

### NetherPortal

`locations/nether_portal.gd` resolves its target at transition time:

```gdscript
func get_target_path() -> String:
    if dungeon_path.is_empty():
        return GameSession.overworld_path
    return dungeon_path
```

`_on_inner_area_2d_body_entered()` uses `get_target_path()` instead of `dungeon_path`.

In `classic/nether.tscn` the `dungeon_path` export of the `NetherPortal` node is cleared (empty string),
so the portal falls back to the session value. The portals in `classic/overworld.tscn` and
`procedural/proc_gen_world.tscn` keep their explicit `res://classic/nether.tscn` path and are unaffected.

### Registering the return path

A world that can be left into the Nether registers itself. `WorldLevel._ready()` gets:

```gdscript
GameSession.set_overworld_path(scene_file_path)
```

guarded so it only happens when the scene actually has a `nether_portal` and `scene_file_path` is not
empty (it is empty for scenes instantiated in tests). This covers both `overworld.tscn` and
`proc_gen_world.tscn` without extra per-scene code. `nether.tscn` itself must **not** overwrite the value
— the guard is therefore: register only if this level's own Nether portal has a non-empty `dungeon_path`
(i.e. it is an "overworld-like" level that leads *into* the Nether).

### ProcGenWorld seed

`_ready()` becomes:

```gdscript
func _ready() -> void:
    generate_world(_resolve_seed())
    super._ready()

func _resolve_seed() -> int:
    if seed_value != 0:
        return seed_value          # explicit override from editor/tests
    return GameSession.get_or_create_world_seed()
```

`_generate_seed()` keeps its current behaviour (fallback to `randi()` when it still receives `0`) so
existing tests continue to work.

Note: enemies/items already defeated or collected before entering the Nether will reappear after
returning, because only the seed is restored, not the world state. That is out of scope here.

## Phases

### Phase 1 – GameSession state
- Add `DEFAULT_OVERWORLD_PATH`, `overworld_path`, `world_seed`.
- Add `set_overworld_path()` and `get_or_create_world_seed()`.
- Extend `reset()` to reset both new fields.
- Tests in `test/test_GameSession.gd`:
  - `reset()` restores the default overworld path and clears the seed.
  - `get_or_create_world_seed()` returns a non-zero value.
  - two consecutive calls return the same value.
  - after `reset()` the seed is regenerated (differs from `0`, i.e. a fresh value is produced).
  - `set_overworld_path()` stores the given path.

### Phase 2 – NetherPortal target resolution
- Add `get_target_path()` to `locations/nether_portal.gd`, use it in `_on_inner_area_2d_body_entered()`.
- New test file `test/test_NetherPortal.gd`:
  - with a non-empty `dungeon_path` the export wins.
  - with an empty `dungeon_path` the value of `GameSession.overworld_path` is returned.

### Phase 3 – Scene wiring
- Clear `dungeon_path` on the `NetherPortal` node in `classic/nether.tscn`.
- Add the registration call to `classic/world_level.gd` (`_setup_locations()` or a new
  `_register_return_path()` called from `_ready()`), including the guard described above.
- Test in `test/test_WorldLevel.gd` (or a new test): a level whose Nether portal leads into the Nether
  sets `GameSession.overworld_path`; a level without a Nether portal leaves it untouched.

### Phase 4 – ProcGenWorld seed usage
- Add `_resolve_seed()` and use it in `_ready()`.
- Tests in the existing ProcGenWorld test file:
  - with `seed_value` set explicitly, that value is used.
  - with `seed_value == 0`, the seed comes from `GameSession` and a second instantiation uses the same seed.

### Phase 5 – Verification
- Run `cmd /c "test_ING.bat < nul" > gut_out.txt 2>&1` and check the summary; delete `gut_out.txt`.
- Manual check in the editor:
  1. Start the procedural world, note the layout, enter the Nether, walk back → same layout, same seed.
  2. Start the classic overworld, enter the Nether, walk back → `overworld.tscn`.
  3. Return to the start menu, start a new game → a different procedural world.
