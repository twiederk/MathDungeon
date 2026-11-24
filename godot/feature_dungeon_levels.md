# Feature Plan: Level-Based Dungeon Content

## Goal

Use `ProceduralGameSession.procedural_level` to control which enemies, weapons, armor, and goods can spawn in a procedural dungeon. Divide the dungeon into easy, medium, and hard room tiers, and select eligible content using the content's level value.

## Current Behavior

- `ProcGenWorld` generates a `Dungeon` from a `LevelConfig`; `ProceduralGameSession` owns the current level and stores it in `LevelConfig.level`.
- `EnemyGenerator` has easy and medium room ranges, level-specific fixed enemy pools, and no hard tier. Enemy spawn chances are 80% and 70%.
- `ItemGenerator` has easy, medium, and hard scene lists with spawn chances of 30%, 25%, and 20%. It assigns tiers using normalized room progress and hard-coded boundaries `0.5` and `0.75`.
- `EnemyStats` has no level field. Weapon level can use `WeaponResource.damage`; armor level can use `ArmorResource.armor`. `GoodResource.damage` is not used by game code.
- Item lists contain repeated healing potion scenes, which currently weight potions more heavily than other entries.

## Content Levels

Add `@export var level: int = 1` to `EnemyStats` and assign procedural enemies as follows:

| Enemy | Level |
| --- | ---: |
| Yellow slime | 1 |
| Cyan slime | 2 |
| Magenta slime | 3 |
| Green slime | 4 |
| Blue slime | 5 |
| Red slime | 6 |
| Skeleton without sword | 3 |
| Skeleton | 5 |

Do not change `WeaponResource` or `ArmorResource`; use weapon `damage` and armor `armor` as their levels. Add `@export var level: int = 1` to `GoodResource` and remove its unused `damage` property. Define a named `GoodResource` constant for the all-dungeon-levels sentinel `0`; goods with that level are eligible at every procedural level. Assign the healing potion to this sentinel so it remains eligible throughout progression.

## Dungeon Tiers and Eligibility

Classify each eligible room by its normalized index in the ordered dungeon leaves:

- Easy: progress is at or below the easy boundary.
- Medium: progress is above the easy boundary and below the hard boundary.
- Hard: progress is at or above the hard boundary.

Keep the current item boundaries (`0.5` and `0.75`) and extract them into named constants, not Inspector exports. Use the same boundaries for enemies so all generators agree on which room belongs to each tier. Preserve the current room ordering and exclude the first and last rooms as the generators do today.

For a procedural dungeon at level `N`, build each tier's eligible pool using these rules:

| Dungeon tier | Eligible content levels |
| --- | --- |
| Easy | `N - 1` and `N` |
| Medium | `N` |
| Hard | `N` and `N + 1` |

Use the enemy level field for enemy pools, and the resource-derived level for item pools. A level-zero good is a special all-level candidate and is included in every item tier. Keep the catalogs in `EnemyGenerator` and `ItemGenerator`, respectively. Build eligible pools from reusable scene/resource catalogs and their levels rather than duplicating filtering rules at each call site. Preserve current item weighting, including the repeated potion entries, unless balancing is intentionally changed. Keep the current spawnable item set; `helmet_cap` is not currently in a spawn pool and should remain excluded unless separately requested.

Clamp the effective procedural level to the maximum supported level in each generator's catalog. The current enemy catalog supports level 6; the current non-sentinel item resources reach level 5. This keeps later levels supplied with the highest supported content without changing the level stored by the session.

## Implementation Plan

### Phase 1: Level Metadata

- Add `EnemyStats.level` and `GoodResource.level`, both defaulting to 1.
- Add a named `GoodResource` constant for level 0 meaning eligible at every dungeon level; assign the healing potion this value.
- Remove unused `GoodResource.damage` after confirming there are no code references.
- Set the requested levels on procedural slime and skeleton stats. Continue using weapon damage and armor rating as item levels.
- Extend `LevelConfig` with `level` and copy it in `duplicate()`. Set it when `ProceduralGameSession` creates each cached configuration. Remove the old fixed easy/medium enemy-pool configuration from `LevelConfig`; generator catalogs will now build pools from resource levels.

### Phase 2: Shared Room Tiers

- Replace the item-tier magic numbers with named constants for the `0.5` easy boundary and `0.75` hard boundary.
- Use one shared tier-calculation convention in both generators: normalized room index divided by leaf count; easy at or below `0.5`, medium above `0.5` and below `0.75`, hard at or above `0.75`.
- Preserve the current room ordering and skip the first and last rooms for both enemy and item placement.
- Add an enemy hard-tier spawn chance of 70%; keep easy/medium enemy chances at 80%/70% and item chances at 30%/25%/20%.

### Phase 3: Level-Based Pools

- Keep an enemy scene catalog in `EnemyGenerator` and an item scene/resource catalog in `ItemGenerator`; retain existing item candidates and duplicate entries used for weighting.
- Determine the effective level by clamping `LevelConfig.level` to the highest non-sentinel content level in that generator's catalog.
- For each dungeon tier, filter catalog entries using the eligibility table above. Always include all-level goods in every item tier.
- Select uniformly from each eligible pool, preserving current spawn probabilities and placement behavior. Skip the spawn when a tier's pool is empty.
- Update `DungeonGenerator` and its callers as needed to pass the enriched `LevelConfig` through to both generators.

### Phase 4: Tests and Regression Checks

- Test default resource levels and every explicit slime/skeleton level; test weapon damage, armor rating, and the all-level good sentinel behavior.
- Test tier boundaries immediately below, on, and above both constants, and confirm both generators classify the same room index identically.
- Test easy/medium/hard eligibility at levels 1, 5, 6, and above the catalog maximum, including the per-generator clamping behavior.
- Verify spawned enemies and items belong to the configured catalog and satisfy their room tier's level rule; verify empty pools do not fail.
- Preserve deterministic generation, enemy entrance placement, item weighting, spawn chances, and existing procedural transitions.
- Run focused `EnemyStats`, `ItemGenerator`, `EnemyGenerator`, `DungeonGenerator`, `ProcGenWorld`, and `GameSession` tests; confirm unrelated resources remain unchanged.

## Confirmed Decisions

- Goods get a dedicated `level` field; `GoodResource.damage` is unused and will be removed.
- Goods at level 0 are eligible at every dungeon level. Use a named constant for this sentinel and assign it to the healing potion.
- Enemy and item tiers share `0.5` and `0.75` boundaries, implemented as code constants rather than Inspector exports.
- Hard-tier enemy spawn chance is 70%.
- Clamp progression to each generator's highest supported content level.
