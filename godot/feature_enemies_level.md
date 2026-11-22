# Feature Plan: Enemies by Procedural Level

## Goal

Choose procedural dungeon enemies from level-specific easy and medium pools. Give the six slime colors distinct stats, ordered from easiest to hardest: yellow, cyan, magenta, green, blue, red.

## Enemy Pools

| Level | Easy | Medium |
| --- | --- | --- |
| 1 | Yellow slime | Yellow slime, cyan slime, skeleton without sword |
| 2 | Cyan slime | Cyan slime, magenta slime, skeleton without sword |
| 3 | Magenta slime | Magenta slime, green slime, skeleton without sword |
| 4 | Green slime, skeleton without sword | Green slime, blue slime, skeleton |
| 5 | Blue slime, skeleton without sword | Blue slime, red slime, skeleton |
| 6 | Red slime, skeleton without sword | Red slime, skeleton |

Within each pool, select each listed enemy with equal probability. Keep the existing easy and medium spawn chances, eligible room ranges, and entrance-based placement.

## Current Behavior

- `ProceduralGameSession` creates and caches a `LevelConfig` per positive level index; callers receive copies. Levels can continue beyond level 6.
- `ProcGenWorld` passes the level's size, split count, and seed to `DungeonGenerator`, which delegates enemy placement to `EnemyGenerator`.
- `EnemyGenerator` currently hard-codes the same easy and medium pools for every level. The original `slime.tscn` and `slime_stats.tres` are the blue slime.
- Each slime color already has its own `EnemyStats` resource, but all six currently have the same gameplay values.

## Proposed Approach

1. Define the table in `ProceduralGameSession` using the existing enemy scenes. Store each level's easy and medium `PackedScene` arrays in its `LevelConfig`, and copy the arrays when duplicating the configuration so callers cannot mutate the cached pools.
2. Pass the configured pools from `ProcGenWorld.generate_world()` through `DungeonGenerator.generate_dungeon()` and `_place_enemies()` to `EnemyGenerator.generate_enemies()`. Remove the hard-coded pools from the generator. Update direct callers to supply explicit valid pools, and handle empty pools without calling `pick_random()` on an empty array.
3. Preserve seeded regeneration: a given level configuration and seed must reproduce its enemy types and positions on revisit. Pool changes may change the generated content, including later random-dependent item selection, compared with the old implementation; identical results across the old and new implementations are not required.
4. Update the six slime stats resources to follow the requested difficulty order in both normal and hard modes. Keep unrelated enemy stats, loot, and behavior unchanged.

## Proposed Balance Decisions

- Levels 7 and deeper: reuse level 6's pools so existing unlimited progression continues. Confirm this fallback before implementation.
- Suggested slime progression: normal maximum hit points of 1, 2, 3, 4, 5, 6 and hard maximum hit points of 2, 3, 4, 5, 6, 7, in the requested color order. Leave damage, armor, arithmetic, number limits, and time limits unchanged. This means stronger slimes require more correct answers and also changes their calculated score. Confirm these values before implementation.

## Implementation Phases

### Phase 1: Level Pool Configuration

- Define all six pool pairs in `ProceduralGameSession`, including the agreed deeper-level fallback.
- Extend `LevelConfig` and its `duplicate()` method to carry independent easy and medium arrays without duplicating the shared scene resources themselves.
- Update configuration construction and direct callers. Preserve invalid-index handling, cached seeds, size growth, and split thresholds.

### Phase 2: Generation Integration

- Pass the pools through `ProcGenWorld`, `DungeonGenerator`, and `EnemyGenerator`; remove the generator's fixed lists.
- Keep each pool's existing room eligibility, spawn chance, equal-weight selection, and placement behavior. Skip the corresponding spawns safely if a pool is empty.
- Update existing generator and world callers for the changed interfaces.

### Phase 3: Slime Difficulty

- Apply the agreed normal and hard stats to the yellow, cyan, magenta, green, blue, and red slime resources in ascending difficulty order.
- Keep each color's separate stats resource and verify unrelated stats and the skeleton resources remain unchanged.

### Phase 4: Verification

- Extend existing focused session and generator checks for the exact pools on levels 1 through 6, the agreed level 7+ behavior, invalid indices, independent configuration copies, and empty pools.
- Check that generated easy and medium enemies belong to the correct pool for their respective rooms, and that repeated generation with the same level configuration and seed reproduces enemy types and positions. Update existing tests affected by the new generator arguments.
- Manually play representative levels in normal and hard modes, including a revisit and a level beyond 6; check enemy variety, the slime difficulty progression, and stairs transitions.

## Acceptance Criteria

- Levels 1 through 6 use exactly the easy and medium pools in the table; deeper levels follow the agreed fallback.
- Every slime color has its own stats resource and is strictly harder than the preceding color in both difficulty modes.
- Spawn rules and entrance-based placement remain unchanged, and revisiting a level reproduces its configured seeded dungeon.