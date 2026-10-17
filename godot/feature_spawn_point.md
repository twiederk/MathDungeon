# Feature: Player Spawn Point

## Goal

The player must appear at the right place when a world scene loads:

- **New game** → the start position authored in the scene (`Player.position`).
- **Returning from the Nether** → next to the Nether portal of that world, not at the start
  position.

Applies to `overworld.tscn` and `proc_gen_world.tscn`. The Nether itself benefits for free,
because its arrival point *is* its portal.

## Decisions

| Topic | Decision |
|---|---|
| State holder | `GameSession.spawn_point` (enum `SpawnPoint { START, NETHER_PORTAL }`) |
| Hook location | `WorldLevel` base class — not per-world scripts |
| Spawn offset | `Marker2D` named `SpawnPoint` inside `nether_portal.tscn`, positionable per instance |
| World persistence on return | **Out of scope.** A fresh world is acceptable for now |
| Return target scene | **Out of scope.** No `GameSession.world_scene_path`; the Nether portal keeps its hardcoded `dungeon_path` |

### Why the hook belongs in `WorldLevel`

`overworld.tscn` has no own script — its root uses `world_level.gd` directly. Both worlds already
have a `Locations/NetherPortal` node, so a single base-class implementation covers both and no new
`overworld.gd` is needed. `ProcGenWorld` inherits it unchanged and can override later if its portal
ever becomes procedurally placed.

## Current state

- `classic/overworld.tscn` — root script `world_level.gd`, `Player.position = (-81, 685)`,
  `Locations/NetherPortal.position = (876, 2512)`.
- `procedural/proc_gen_world.tscn` — root script `proc_gen_world.gd`, `Player.position = (48, 864)`,
  `Locations/NetherPortal.position = (2177, 1314)`.
- `locations/nether_portal.gd` — `_on_inner_area_2d_body_entered()` calls
  `change_scene_to_file(dungeon_path)`. Same script on both sides of the portal.
- `locations/nether_portal.tscn` — `OuterArea2D` shape 128×160, `InnerArea2D` shape 48×80, both
  centred on the portal origin.
- `gui/start_menu.gd` — both start buttons call `GameSession.reset()` before changing scene.
- `classic/world_level.gd` — `_ready()` runs `_setup_signals()`, `_setup_locations()`,
  `_setup_limits_and_borders()`, `_setup_character_stats()`, `_setup_player_portrait()`.

## Known hazards

1. **Re-trigger bounce.** If the player spawns inside `InnerArea2D`, `body_entered` fires on arrival
   and sends them straight back to the Nether. The `SpawnPoint` marker must sit outside both areas:
   `InnerArea2D` reaches 40 px below the origin, `OuterArea2D` 80 px. Default marker position
   `(0, 96)` clears both.
2. **Camera snap.** `_setup_limits_and_borders()` applies the camera limits. The player position must
   be set *before* that call so the limits are evaluated against the final position.

## Phases

### Phase 1 — `SpawnPoint` marker in the portal scene

`locations/nether_portal.tscn`:

- Add child `Marker2D` named `SpawnPoint` at `position = Vector2(0, 96)`.

`locations/nether_portal.gd`:

- Add `@onready var spawn_point: Marker2D = $SpawnPoint`.
- Add `func get_spawn_position() -> Vector2: return spawn_point.global_position`.

The marker is editable per instance (`editable_instance` / overriding `position` on the instanced
node), so each world can nudge it without touching the shared scene.

### Phase 2 — spawn state in `GameSession`

`classic/game_session.gd`:

```gdscript
enum SpawnPoint {
	START,
	NETHER_PORTAL
}

var spawn_point: int = SpawnPoint.START
```

- `reset()` sets `spawn_point = SpawnPoint.START`. Both start buttons already call `reset()`, so a
  new game starts at the authored position with no further change to `start_menu.gd`.

### Phase 3 — set the state when traversing the portal

`locations/nether_portal.gd`:

```gdscript
func _on_inner_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player" or not active:
		return
	GameSession.spawn_point = GameSession.SpawnPoint.NETHER_PORTAL
	get_tree().call_deferred("change_scene_to_file", dungeon_path)
```

Because the same script runs on both sides, entering the Nether also sets `NETHER_PORTAL` — which is
the correct arrival point there too.

### Phase 4 — apply the position in `WorldLevel`

`classic/world_level.gd`:

```gdscript
func _ready() -> void:
	_apply_start_position()
	_setup_signals()
	...

func _apply_start_position() -> void:
	player.global_position = get_start_position()


func get_start_position() -> Vector2:
	if GameSession.spawn_point == GameSession.SpawnPoint.NETHER_PORTAL:
		var portal := get_node_or_null("Locations/NetherPortal") as NetherPortal
		if portal:
			return portal.get_spawn_position()
	return player.global_position
```

`_apply_start_position()` runs first so `_setup_limits_and_borders()` sees the final position.
`ProcGenWorld._ready()` keeps calling `generate_world()` before `super._ready()`.

`classic/end.tscn` has no `Locations/NetherPortal`, so `get_node_or_null` returns `null` and the
authored player position is used — correct, the End is only reachable through the End portal.

## Tests (`test/`, GUT)

| Test | Expectation |
|---|---|
| `test_game_session.gd` | `reset()` sets `spawn_point` to `START` |
| `test_nether_portal.gd` | `get_spawn_position()` returns the marker's `global_position`, offset from the portal |
| `test_world_level.gd` | `START` → player keeps the authored position; `NETHER_PORTAL` → player sits at the portal's spawn position |
| `test_nether_portal.gd` | The spawn position lies outside `InnerArea2D` (guards hazard 1) |

Run with `test_ING.bat`. After adding scripts with a new `class_name` outside the editor, run a
headless `--import` once so the class cache and `.uid` files are generated.

## Out of scope / follow-ups

- **World persistence.** `change_scene_to_file` reloads the scene from disk: defeated enemies,
  collected items and picked-up companions return, and `_setup_locations()` re-registers everything
  with `AchievementManager`. For `ProcGenWorld` the seed is `0` in the scene file, so returning
  generates a *different* world.
- **Return target.** `nether.tscn` hardcodes `dungeon_path = "res://classic/overworld.tscn"`, so a
  procedural run that passes through the Nether comes back into the classic overworld.
