# Feature: Loot System

## Goal

Defeated enemies can drop configured pickup items. Each enemy's drop entries and their drop probabilities are authored through its `EnemyStats` resource. The first shippable slice is a guaranteed drop of one Eye of Ender from each Enderman defeated.

## Current State

- `EnemyStats` contains combat configuration but no loot data.
- `Enemy.hurt()` applies damage and returns remaining hit points. `QuizDialog._answer_correct()` handles the defeat path and frees the enemy.
- `WorldLevel` has `Enemies` and `Items` roots. It connects pickup signals for items found under `Items` during `_ready()`.
- `ProcGenWorld` extends `WorldLevel` and adds generated items through inherited `items_root` before calling `super._ready()`.
- Pickup scenes already implement `Item.item_picked_up` and `Item.execute()`. `EyeOfEnder.execute()` increments `GameSession.eyes_of_ender`.
- The End portal requires 12 Eyes of Ender. Enderman stats are authored in `enemies/enderman_stats.tres`.

## Design Decisions

| Topic | Decision |
|---|---|
| Drop configuration | Add a typed loot-drop Resource containing an item `PackedScene` and a probability from 0.0 to 1.0. `EnemyStats` exports an array of these entries. |
| Roll behavior | Roll each configured entry once per enemy defeat. Entries are independent, so a future enemy can drop more than one item if multiple entries succeed. Keep the first Enderman table to one 100% entry. |
| Defeat ownership | `Enemy` reports defeat once; `WorldLevel` owns the drop roll and spawning. `QuizDialog` remains responsible for combat UI, score, and freeing the enemy, not item placement. |
| Item ownership | Parent every dropped pickup under the current world's `Items` node, just like authored and generated pickups. |
| Pickup hookup | Register dynamically spawned items with the same pickup-signal hookup used for scene-authored items. Adding a child alone is insufficient because `_setup_signals()` currently only visits existing children during `_ready()`. |
| Spawn location | Spawn at the defeated enemy's global position so the drop appears where the enemy died, even if scene transforms later differ. |
| Invalid configuration | Skip null or invalid item scenes and treat probabilities outside 0.0–1.0 as invalid configuration rather than silently clamping them. |

## Implementation Phases

### Phase 1 — Define loot data

1. Add a `LootDropDefinition` Resource, for example in `items/loot_drop_definition.gd`, with an exported `PackedScene` and exported probability.
2. Add `loot_drops: Array[LootDropDefinition]` to `EnemyStats`, defaulting to an empty array so existing enemy resources keep their current behavior.
3. Configure `enemies/enderman_stats.tres` with one `res://items/eye_of_ender.tscn` entry at probability `1.0`.

### Phase 2 — Report enemy defeat once

1. Add a `defeated` signal to `Enemy` and emit it when damage first reduces hit points to zero or below.
2. Guard the transition so subsequent damage cannot emit duplicate defeat events or produce duplicate drops.
3. Keep the existing `hurt()` return value and `QuizDialog` kill flow compatible. The defeat event must fire synchronously before `QuizDialog` queues the enemy for deletion.

### Phase 3 — Spawn loot through `WorldLevel`

1. Connect each enemy's `defeated` signal while registering the enemies in `WorldLevel._setup_signals()`.
2. Add a world-level handler that reads the enemy's `stats.loot_drops`, rolls each configured entry, instantiates successful item scenes, adds them to `items_root`, and places them at the enemy's global position.
3. Extract/reuse an item-registration helper for pickup signal hookup. Call it both for items present during `_ready()` and for each spawned drop, so dynamic pickups execute through the existing `_on_item_picked_up()` path.
4. Confirm `ProcGenWorld` works through inheritance: its generated enemies are added before `super._ready()`, and its generated pickups already use the same `items_root`.

### Phase 4 — Verify the Enderman first slice

1. Defeat an Enderman in overworld, nether, end, and a procedural dungeon; each defeat creates one Eye of Ender at the enemy's location.
2. Walk into each dropped eye and verify it increments the existing eye count and contributes to activating the End portal.
3. Defeat an enemy with no configured loot and verify no item appears; confirm the Enderman cannot generate duplicate drops from repeated damage or signal handling.

## Tests

Use the existing GUT test suite and keep probability assertions deterministic rather than relying on statistical repetitions:

- Test that new/default `EnemyStats` has no loot entries and preserves existing enemy behavior.
- Test the loot-roll helper with explicit roll values at the success/failure boundaries, including probabilities 0.0 and 1.0.
- Test that lethal damage emits `defeated` once and nonlethal damage does not emit it.
- Test that a successful drop is parented under `Items`, positioned at the defeated enemy, and has its pickup signal connected.
- Test Enderman's configured Eye of Ender scene and guaranteed probability.

## Acceptance Criteria

- Loot entries and their probabilities are editable per enemy in the Inspector through its `EnemyStats` resource.
- Defeating an Enderman produces exactly one Eye of Ender pickup; defeating other enemies produces only their configured drops.
- Dropped items are children of the active world's `Items` node and can be picked up with the existing behavior.
- Authored pickups, procedural pickups, combat, scoring, and portal progression continue to work.
- No random-probability test is flaky; boundary behavior is covered deterministically.

## Notes

Using the world's `Items` node is the right ownership model for loot. It keeps all pickups in one discoverable scene subtree, gives them the same world lifetime and transform context as existing items, and lets the existing item scripts remain unaware of whether an item was authored into the scene, generated procedurally, or dropped by an enemy. The required change is to register dynamically added pickups, since current signal wiring only sees the initial children.
