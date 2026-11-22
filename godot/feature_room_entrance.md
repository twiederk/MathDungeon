# Feature Plan: Enemy Placement Near Room Entrances

## Goal

Place procedural dungeon enemies on room floor tiles next to an entrance instead of always placing them at the room center. Keep the existing enemy types, spawn chances, and room eligibility rules.

## Current Behavior

- `DungeonGenerator.generate_dungeon()` carves room floors and paths before generating enemies. `_place_enemies()` currently passes only the branch tree to `EnemyGenerator`.
- A leaf `Branch` describes a partition, not the exact room floor rectangle. `_place_rooms()` excludes the top and left padding cells; paths can carve through those cells. Room boundaries must match the existing carving logic rather than the full branch rectangle.
- `EnemyGenerator.generate_enemies()` places each selected enemy at `room.get_center()`. Items also use room centers, and stairs use the first and last room centers.
- Enemy positions are tile coordinates until `ProcGenWorld` converts them to world coordinates. Dungeon generation uses the global seeded random stream, including for items.

## Proposed Approach

1. Pass the completed floor layout from `DungeonGenerator` to `EnemyGenerator` after rooms and paths have been carved. Build a coordinate lookup once so entrance checks do not repeatedly scan the floor array. Treat duplicate floor coordinates as one tile.
2. Derive each room's original carved floor footprint using the same bounds and padding rules as `_place_rooms()`; share that calculation where practical so the two cannot drift apart. Do not equate the partition boundary with the room boundary.
3. For each room floor tile on the footprint boundary, check its four cardinal neighbors. A neighboring generated floor tile outside that room's original footprint represents an opening; the room tile is a candidate spawn immediately inside the entrance. This also detects corridors carved in padding cells within the same branch. Do not count diagonal contact or a corridor tile itself as the spawn position.
4. Deduplicate candidates and use a stable traversal order. Select a candidate deterministically without additional random draws, preserving the existing random stream and item generation behavior. Keep the existing enemy selection and chance logic unchanged.
5. If there are no candidates, fall back to a valid floor tile within the room footprint nearest the room center, using a stable tie-break. If the footprint contains no valid floor tile, skip that enemy rather than spawning on a wall or outside the room. Keep existing item and stair placement unchanged; recognize that the fallback may coincide with a room-center item in a very small or entrance-less room.

## Implementation Phases

### Phase 1: Room Footprints and Floor Data

- Share or otherwise align the room footprint calculation with `_place_rooms()` and pass the completed floor layout to enemy generation.
- Build a deduplicated floor lookup and update affected callers and existing tests.
- Check that room carving and seeded dungeon generation still work.

GUT tests:

- For a branch with a known position and size, assert that the footprint matches `_place_rooms()`, including excluded top and left padding and included bottom and right edges.
- For a tiny branch with no carved tiles, assert that the footprint is empty.
- Update `test_place_enemies` to supply the carved room and path floors; assert generation succeeds and free the instantiated enemies.
- Supply repeated floor coordinates and assert the lookup contains each coordinate only once.

### Phase 2: Entrance Detection

- Find room-boundary floor tiles with cardinally adjacent generated floor outside the room footprint, in a stable order.
- Add focused tests for each side, padding openings, multiple openings, duplicate floors, closed boundaries, and diagonal contact.

GUT tests:

- Use explicit floor layouts to assert the exact candidate room tile for each of the four sides, including a corridor in top or left branch padding.
- Assert multiple openings produce the expected distinct candidates in stable order, even when floor coordinates are duplicated or reordered.
- Assert closed boundaries and diagonal-only outside floor tiles produce no candidates; corridor and wall tiles must not be returned as room candidates.

### Phase 3: Enemy Placement and Fallback

- Use a detected candidate for each selected enemy without additional random draws; preserve existing enemy pools, spawn chances, and room eligibility.
- Implement and test the nearest-valid-floor fallback and the empty-footprint skip.
- Verify spawned enemies occupy valid room floor tiles and that entrance-based positions are adjacent to openings.

GUT tests:

- For a room with multiple entrance candidates, assert the selected spawn is a valid candidate and remains the same for the same layout without consuming a random draw.
- For a room without entrances, assert the fallback is a valid footprint floor nearest the center and uses a stable tie-break; test a small room where the center is unavailable.
- For an empty footprint, assert no enemy is spawned and no invalid position is returned.
- With a controlled seed and room tree, assert spawned enemies belong to the existing eligible rooms and appropriate enemy pools; free every instantiated enemy.

### Phase 4: Integration and Validation

- Extend fixed-seed regeneration and representative generated-dungeon tests to cover enemy placement and item signatures.
- Run focused dungeon generator GUT tests and the normal test suite; confirm tile-to-world conversion and stairs remain unchanged.

GUT tests:

- Extend `test_progression_regeneration_is_deterministic` to assert matching enemy positions and scene paths, item signatures, floor and wall layouts, and stairs for repeated generation with the same nonzero seed.
- Generate a representative dungeon with a fixed seed and assert each enemy is in its eligible room, on a floor tile, and next to an entrance when one exists; otherwise assert the documented fallback.
- Retain the existing stairs checks and add or reuse a world-placement test to verify enemy tile positions convert to tile centers. Free generated enemies and items.

## Verification

- Add focused GUT tests with explicit room footprints and floor layouts for openings on all four sides, including an opening in a branch's padding, multiple openings, duplicate floor entries, closed boundaries, and diagonal-only contact.
- Verify every chosen entrance spawn is an actual room floor tile with a cardinally adjacent floor tile outside the original footprint, and that no entrance yields the documented fallback or skip behavior, including tiny or empty footprints.
- Update the existing `_place_enemies` test for its new floor-layout input. Check generated enemies remain on floor tiles in eligible rooms, with existing enemy pools and spawn rules preserved.
- Extend the fixed-seed regeneration test to continue checking enemy and item signatures, and cover a representative generated dungeon with entrance-based placement. Free instantiated enemies and items in tests.
- Run the focused dungeon generator GUT tests, then the project's normal test suite. Confirm that world-coordinate conversion remains unchanged.

## Acceptance Criteria

- In a room with an entrance candidate, a spawned enemy occupies a room floor tile immediately adjacent to an opening.
- Missing entrances and degenerate rooms follow the fallback rules without invalid placements or errors.
- The same nonzero seed and configuration reproduce the same dungeon and content; spawn chances, enemy pools, stairs, and item generation behavior remain unchanged.