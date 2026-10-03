# Feature: Allay as Companion

## Goal

Convert the `Allay` animal (currently a passive `Animal` in `animals/allay.tscn`) into a
pickup-able companion, following the same pattern as `Wolf`. After this change, `Allay`
instances behave exactly like `Wolf`: they sit in the world, get picked up by the player,
follow the player, and are persisted via `Character.companions`.

## Current state (reference: Wolf)

- `companions/companion.gd` (`Companion`, extends `CharacterBody2D`): generic pickup +
  follow behavior (`PickupArea`, `start_following`, `execute()` placeholder).
- `companions/wolf.gd` (`Wolf`, extends `Companion`): overrides `execute()` to play a sound
  and register itself with `CharacterManager.current.add_companion(str(get_path()))`.
- `companions/wolf.tscn`: `CharacterBody2D` root (`collision_layer = 2`, `collision_mask = 3`),
  child `Sprite2D` (creatures.png spritesheet), child `CollisionShape2D` (capsule, for
  movement/physics), child `PickupArea` (`Area2D`, `collision_layer = 2`) with its own
  `CollisionShape2D` (rectangle, for pickup detection).
- `classic/main.tscn`, `classic/nether.tscn`, `classic/end.tscn`,
  `procedural/proc_gen_world.tscn` each have a `Companions` node containing `Wolf`/`Wolf2`
  instances.
- `classic/main.gd`: iterates `companions_root` children to connect `companion_picked_up`,
  and `_setup_companions()` re-attaches persisted companions (by node path) to the player.

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

var damage_applied: bool = false


func execute() -> void:
	if not damage_applied:
		damage_applied = true
		CharacterManager.current.add_companion(str(get_path()))


func set_damage_applied() -> void:
	damage_applied = true
```

Mirrors `Wolf`, minus the `Sound.play(Sound.dog_bark)` call and the `damage` export (Allay
has no attack/damage stat). No pickup sound asset exists for Allay yet — skip audio for now,
or reuse `Sound.dog_bark` if the user wants a placeholder sound until a dedicated asset
exists (needs a decision).

### 2. Create `companions/allay.tscn`

Model it directly after `companions/wolf.tscn`:

- Root node `Allay`, type `CharacterBody2D`, `collision_layer = 2`, `collision_mask = 3`,
  script `res://companions/allay.gd`.
- `Sprite2D` using `res://enemies/creatures.png`, `hframes = 9`, `vframes = 9`,
  `frame = 63` (same frame Allay already uses).
- `CollisionShape2D` with a shape suited to movement collision (reuse/adapt the existing
  circle shape from `animals/allay.tscn`, or a capsule like Wolf's — needs a quick visual
  check in-editor).
- `PickupArea` (`Area2D`, `collision_layer = 2`) with its own `CollisionShape2D` sized to
  the sprite for pickup detection.

### 3. Retire `animals/allay.tscn`

- Delete `animals/allay.tscn` (and its `.uid`/cache entries) once the new companion scene
  replaces all usages. Do **not** touch `animals/animal.gd` — it's still shared by the other
  animals (axolotl, frog, tadpole, etc.).

### 4. Update scene files

For `classic/main.tscn`, `classic/nether.tscn`, `classic/end.tscn`, and
`procedural/proc_gen_world.tscn`:

- Add an `ext_resource` for `res://companions/allay.tscn`.
- Add `Allay` node instance(s) as a child of the existing `Companions` node, placed below
  the `Wolf`/`Wolf2` entries (give them a reasonable `position` like the existing
  Wolf/Wolf2 offsets).
- In `classic/main.tscn` specifically: remove the existing `Allay` / `Allay2` nodes from
  the `Animals` node and their now-unused `res://animals/allay.tscn` `ext_resource` (unless
  other animal instances still reference it — they don't, per current scan).
- `nether.tscn`, `end.tscn`, `proc_gen_world.tscn` currently have no Allay instance at all —
  add one new `Allay` instance to each, under `Companions`.

### 5. No script changes needed in `main.gd`

`_setup_signals()` and `_setup_companions()` already operate generically on
`companions_root.get_children()` / stored node paths, so `Allay` is picked up automatically
once it lives under the `Companions` node and extends `Companion`.

### 6. Testing

- No existing `test_Wolf.gd` to mirror. Optionally add `test/test_Allay.gd` verifying
  `execute()` calls `CharacterManager.current.add_companion` and that `set_damage_applied()`
  prevents double-registration — same shape as a hypothetical Wolf test, if desired.

## Open questions

1. Should Allay play a pickup sound (reuse `Sound.dog_bark` placeholder, add a new
   `Sound.allay_pickup` stream, or stay silent)?
2. Exact `CollisionShape2D` shape/size for the new `Allay` companion body (reuse the old
   circle from `animals/allay.tscn` vs. a capsule like Wolf).
3. Positions for the new `Allay` instances in `nether.tscn`, `end.tscn`, and
   `proc_gen_world.tscn` (none exist today, so placement is arbitrary/new).
