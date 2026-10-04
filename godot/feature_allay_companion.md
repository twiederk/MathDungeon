# Feature: Allay as Companion

## Goal

Convert the `Allay` animal (currently a passive `Animal` in `animals/allay.tscn`) into a
pickup-able companion, following the same pattern as `Wolf`. After this change, `Allay`
instances behave exactly like `Wolf`: they sit in the world, get picked up by the player,
follow the player, and are persisted via `Character.companions` (a type-based array).

## Current state (reference: Wolf)

**Architecture:**
- Companions are identified by **type name** (e.g., "Wolf", "Allay"), stored in
  `Character.companions: Array[String]`.
- On pickup, the type is registered via `CharacterManager.current.add_companion_type(String(companion.get_script().get_global_name()))`.
- On level load, `CompanionSetup` iterates through `Character.companions` and either claims
  existing matching children or instantiates new ones from the `COMPANION_SCENES` lookup table.
- Damage calculation reads `Character.companions`, not node paths.

**Key files:**
- `companions/companion.gd` (`Companion`, extends `CharacterBody2D`): generic pickup +
  follow behavior (`PickupArea`, `start_following`, `execute()` placeholder).
- `companions/wolf.gd` (`Wolf`, extends `Companion`): overrides `execute()` to play
  `Sound.dog_bark`.
- `companions/wolf.tscn`: `CharacterBody2D` root (`collision_layer = 2`, `collision_mask = 3`),
  child `Sprite2D` (creatures.png spritesheet), child `CollisionShape2D` (capsule, for
  movement/physics), child `PickupArea` (`Area2D`, `collision_layer = 2`) with its own
  `CollisionShape2D` (rectangle, for pickup detection).
- `classic/companion_setup.gd` (`CompanionSetup`): class that handles companion instantiation
  and positioning. Uses `COMPANION_SCENES` lookup table to map type names to scene paths.
  Called from `classic/main.gd` during `_ready()`.
- `classic/main.tscn`, `classic/nether.tscn`, `classic/end.tscn`,
  `procedural/proc_gen_world.tscn` each have a `Companions` node containing `Wolf`/`Wolf2`
  instances.
- `classic/main.gd`: no longer has companion setup logic—delegates to `CompanionSetup`.

## Current state of Allay

- `animals/allay.tscn`: `StaticBody2D` root using `animals/animal.gd` (`class_name Animal`),
  a `Sprite2D` (creatures.png, `frame = 63`) and a `CollisionShape2D` (circle, radius ~15).
  No pickup/follow behavior.
- Only referenced today in `classic/main.tscn`, under the `Animals` node (`Allay`, `Allay2`),
  purely decorative.

## Implementation steps

### 1. Create `companions/allay.gd`

```gdscript
class_name Allay
extends Companion


func execute() -> void:
	Sound.play(Sound.dog_bark)
```

Mirrors `Wolf`, with the same `execute()` pattern. Currently plays `Sound.dog_bark` as a
placeholder. No special bookkeeping needed—the pickup logic is handled by
`Companion.PickupArea` → `_on_companion_picked_up()` in `main.gd`, which calls
`add_companion_type(String(companion.get_script().get_global_name()))` automatically.
**Note**: Once a dedicated Allay pickup sound asset is created, replace `Sound.dog_bark`
with the new asset identifier.

### 2. Create `companions/allay.tscn`

Model it directly after `companions/wolf.tscn`:

- Root node `Allay`, type `CharacterBody2D`, `collision_layer = 2`, `collision_mask = 3`,
  script `res://companions/allay.gd`.
- `Sprite2D` using `res://enemies/creatures.png`, `hframes = 9`, `vframes = 9`,
  `frame = 63` (same frame Allay already uses).
- `CollisionShape2D` with a **capsule shape** (like Wolf's) for movement collision,
  sized appropriately for Allay's sprite.
- `PickupArea` (`Area2D`, `collision_layer = 2`) with its own `CollisionShape2D` sized to
  the sprite for pickup detection.

### 3. Register Allay in `CompanionSetup.COMPANION_SCENES`

In `classic/companion_setup.gd`, add `Allay` to the lookup table:

```gdscript
const COMPANION_SCENES := {
	"Wolf": "res://companions/wolf.tscn",
	"Allay": "res://companions/allay.tscn",
}
```

This tells the system how to instantiate Allay when its type is encountered in
`Character.companions`.

### 4. Retire `animals/allay.tscn`

- Delete `animals/allay.tscn` (and its `.uid`/cache entries) once the new companion scene
  replaces all usages. Do **not** touch `animals/animal.gd` — it's still shared by the other
  animals (axolotl, frog, tadpole, etc.).

### 5. Update scene files

For `classic/main.tscn`, `classic/nether.tscn`, `classic/end.tscn`, and
`procedural/proc_gen_world.tscn`:

- Add an `ext_resource` for `res://companions/allay.tscn`.
- Add `Allay` node instance as a child of the existing `Companions` node, positioned
  next to the player following the same offset pattern as Wolf:
  `position = player.global_position + Vector2(60.0 + (i * 40.0), 0.0)` where `i` is
  the companion index (e.g., i=1 for first Allay).
- In `classic/main.tscn` specifically: remove the existing `Allay` / `Allay2` nodes from
  the `Animals` node and their now-unused `res://animals/allay.tscn` `ext_resource` (unless
  other animal instances still reference it — they don't, per current scan).
- `nether.tscn`, `end.tscn`, `proc_gen_world.tscn` currently have no Allay instance at all —
  add one new `Allay` instance to each, under `Companions`.

### 6. Verify automatic pickup handling

`_on_companion_picked_up()` in `main.gd` already handles any `Companion` that emits
`companion_picked_up`. It automatically:
- Registers the type via `add_companion_type(String(companion.get_script().get_global_name()))`
  (which extracts "Allay" from the Allay instance).
- Calls `companion.execute()` (which plays the sound).
- Calls `companion.start_following(player)`.

No further changes to `main.gd` are needed.

### 7. Testing (optional)

No existing `test_Allay.gd` required. The type-based persistence system is already tested
via `test_Character.gd` (which verifies damage calculation from the `companions` array).
Allay will automatically be covered once a test adds "Allay" to a character's `companions`
array and verifies `get_total_damage()` correctly ignores unknown types (same as the existing
`test_get_total_damage_ignores_unknown_companion_types()` test).

## Open questions

**RESOLVED:**

1. ✅ **Sound**: Allay reuses `Sound.dog_bark` as placeholder. When a dedicated Allay pickup sound asset is created, update `Allay.execute()` to play it.
2. ✅ **Collision shape**: Allay uses a capsule collision shape (like Wolf) for consistency.
3. ✅ **Positions**: Allay instances are placed next to the player in each level, matching the Wolf offsets pattern (`position = player.global_position + Vector2(60.0 + (i * 40.0), 0.0)`).
4. ✅ **Damage**: Allay remains non-damaging—it contributes 0 to total damage. Only Wolf adds damage.
