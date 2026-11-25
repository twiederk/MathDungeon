# Item Refactoring Feature Plan

## Feature Summary

Simplify item handling by separating item data resources from collectible item scenes and by making procedural catalogs contain scenes only. Introduce a shared `ItemResource` base, rename the collectible scene base from `Item` to `ItemScene`, and expose each scene's resource and level through a common API. Apply the same scene-level lookup pattern to procedural enemies, with `Enemy.get_level()` delegating to `EnemyStats.level`.

## Goals

- Make `WeaponResource`, `ArmorResource`, and `GoodResource` inherit shared `id`, `name`, and `icon_atlas` fields and the common resource API from `ItemResource`.
- Keep resource-specific level calculations in each concrete resource's `get_level()` override.
- Make weapon, armor, and good collectible scene scripts inherit `ItemScene` and expose their associated item resource and level.
- Replace procedural scene/resource definition dictionaries with arrays of `PackedScene` values.
- Keep generated item and enemy pools, tier eligibility, and gameplay behavior unchanged.
- Update all script types, scene/resource references, and tests affected by the rename and data migration.

## Non-Goals

- Do not make `Enemy` inherit `ItemResource` or the item scene hierarchy. `get_item_resource()` is specific to item scenes/resources.
- Do not convert the existing `items/item_catalog.tres` resource catalog to a scene catalog. It remains a catalog of typed item resources for existing inventory/save/load lookup behavior.
- Do not change item effects, enemy stats, spawn probabilities, loot behavior, or level/tier rules beyond sourcing levels through the new scene APIs.

## Acceptance Criteria

- The three concrete item resources extend `ItemResource`; the shared fields are declared only on the base, and each concrete resource retains its current level semantics.
- `ItemScene` is the collectible scene base class. All item scripts that previously extended `Item` extend `ItemScene`, and provide `get_item_resource()` and `get_level()` for their concrete resource type.
- All project references to the old `Item` class and script path are migrated, including typed arrays, signals, pickup handling, loot drops, and serialized scene script references.
- `ItemGenerator.ITEM_CATALOG` and `EnemyGenerator.ENEMY_CATALOG` contain scenes only. Their eligibility and maximum-level calculations derive levels from instantiated scene APIs rather than parallel resource/stat dictionary entries.
- `Enemy.get_level()` returns `stats.level`; enemy scenes remain ordinary `Enemy` scenes with `EnemyStats` and do not enter the item resource hierarchy.
- Existing procedural pool membership/order and item/enemy placement behavior remain covered and unchanged.
- Relevant GUT tests pass after each implementation step.

## Assumptions and Open Questions

- The requested public methods are `ItemScene.get_item_resource()`, `ItemScene.get_level()`, and `Enemy.get_level()`; concrete item scene scripts override the first two, while enemy level delegates to its assigned `stats` resource.
- The current `ItemCatalog` resource arrays and lookup API remain unchanged except for verifying compatibility with the new resource inheritance.
- Procedural generators may instantiate catalog scenes to query their level; those temporary nodes must be freed and must not be added to the active scene tree.
- No unresolved product decisions remain from the previous discussion.

## Ordered Implementation Plan

### 1. Add the shared item resource base and migrate resource definitions

- Add `items/item_resource.gd` as `ItemResource`, extending `Resource`, with exported `id`, `name`, and `icon_atlas` fields and the common `get_level()` contract.
- Change `items/weapon_resource.gd`, `items/armor_resource.gd`, and `items/good_resource.gd` to extend `ItemResource`; remove their duplicate shared exports and preserve their concrete level formulas and good-level sentinel behavior.
- Update every serialized resource using these scripts, including resources under `items/` and `procedural/items/`. Preserve each resource's IDs, names, icons, stats, and script references.
- Keep `items/item_catalog.gd` and `items/item_catalog.tres` resource-typed; verify inherited concrete resources still resolve through its weapon, armor, and good lookups.
- **GUT coverage in this step:** Add `test/test_ItemResource.gd` for inherited shared properties and concrete `get_level()` behavior (weapon damage formula, armor formula, ordinary good level, and the all-dungeon-levels good sentinel). Extend or retain `test/test_ItemCatalog.gd` to verify resource lookup compatibility, and retain the resource-level assertions in `test/test_EnemyStats.gd` for the healing-potion sentinel.

### 2. Rename `Item` to `ItemScene` and add the item-scene API

- Rename `items/item.gd` to `items/item_scene.gd` and its global class to `ItemScene`. Keep its existing pickup signal, pickup detection, texture helper, and `execute()` behavior.
- Add `get_item_resource()` and `get_level()` to `ItemScene` as the shared item-scene contract. Update `items/sword.gd`, `items/armor.gd`, `items/healing_potion.gd`, `items/lighter.gd`, and `items/eye_of_ender.gd` to extend `ItemScene` and override both methods, returning their existing `WeaponResource`, `ArmorResource`, or `GoodResource` and delegating level calculation to that resource.
- Update all concrete item scene references and serialized scripts/properties in `items/*.tscn` and `procedural/items/*.tscn` as needed, preserving existing resource assignments.
- Replace old `Item` type annotations/references throughout the owning code paths: `classic/world_level.gd`, `items/loot_dropper.gd`, `procedural/item_generator.gd`, `procedural/dungeon_generator.gd`, `procedural/dungeon.gd`, and any other project-wide usages found by search. Update the typed item pickup signal accordingly. Do not change unrelated uses of the ordinary word “item” or GUT internals.
- **GUT coverage in this step:** Extend `test/test_Sword.gd`, `test/test_Armor.gd`, `test/test_HealingPotion.gd`, and `test/test_Lighter.gd` to assert `get_item_resource()` returns the assigned resource and `get_level()` delegates correctly while retaining their `execute()` behavior tests. Add focused `test/test_ItemScene.gd` coverage for the base pickup/API contract and the `EyeOfEnder` item scene, which currently has no dedicated test. Update or add a loot-dropper assertion if its return type or instantiated scene typing needs coverage.

### 3. Move enemy level lookup onto enemy scenes and convert the enemy catalog

- Add `Enemy.get_level()` in `enemies/enemy.gd`, returning `stats.level` without introducing any item-resource inheritance or item-specific API.
- Replace `EnemyGenerator.ENEMY_CATALOG`'s scene/stats dictionaries with an array of the existing enemy `PackedScene` constants. Remove the parallel stats-resource preloads from the catalog.
- Update `_get_enemy_pool()` and `_get_max_enemy_level()` in `procedural/enemy_generator.gd` to instantiate each catalog scene as an `Enemy`, read `get_level()`, free the temporary instance, and retain the existing level clamping, tier filtering, and catalog order.
- **GUT coverage in this step:** Extend `test/test_Enemy.gd` to assert `get_level()` reflects the attached `EnemyStats.level`, including a changed level after assignment. Extend `test/test_DungeonGenerator.gd`'s parameterized enemy-pool cases to preserve exact expected scene names/order and level/tier boundaries; retain procedural-world coverage in `test/test_ProcGenWorld.gd` to ensure generated enemies still come from eligible scene pools.

### 4. Convert the item generator catalog to scenes and source eligibility from item scenes

- Replace `ItemGenerator.ITEM_CATALOG` scene/resource dictionaries in `procedural/item_generator.gd` with an array of the existing item `PackedScene` constants.
- Update `_get_item_pool_for_level()` and `_get_max_item_level()` to instantiate catalog entries as `ItemScene`, query `get_level()` (and use `get_item_resource()` only where the resource itself is needed), then free each temporary instance. Preserve the all-dungeon-levels good sentinel rule and existing pool ordering.
- Remove now-unneeded resource constants from `ItemGenerator`; keep scene constants and avoid adding a second parallel resource catalog.
- **GUT coverage in this step:** Extend `test/test_DungeonGenerator.gd`'s parameterized item-pool cases to preserve the existing scene names/order, all-levels good behavior, tier boundaries, and maximum-level clamping. Retain the seeded item-placement assertions and add an assertion that each generated item is an `ItemScene` whose reported level is eligible for its room tier. Run the focused GUT coverage for the changed resource, item scene, enemy, and dungeon-generator tests after the catalog migration.
