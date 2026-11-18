# Feature: Screen-Sized Procedural Level Progression

## Goal

Start procedural dungeons at approximately one logical screen, grow them gradually every second level, and cap their dimensions at a practical maximum. Keep BSP split depth reasonable through a small lookup table in the session progression code.

This document is an implementation plan. No gameplay changes are implemented as part of creating it.

## Scope and decisions

- Apply only to procedural mode; classic mode remains unchanged.
- Read the logical viewport dimensions from the project settings, not the physical window size or runtime window resizing.
- Use `ProcGenWorld.TILE_SIZE` as the tile-size source of truth.
- Levels 1 and 2 have the starting dimensions. Grow by `Vector2i(5, 5)` on levels 3, 5, 7, and so on.
- Clamp each dimension independently to `Vector2i(120, 120)`.
- Continue creating new levels and seeds after reaching the cap; only dimensions and split depth stop growing.
- Do not modify `DungeonGenerator`, `Branch`, or the BSP algorithm. Control the existing split argument through a lookup table instead.
- Preserve cached per-level configurations, deterministic revisits, reset behavior, stairs, and player/session state.

## Current implementation

- `classic/procedural_game_session.gd` owns procedural configuration creation and caching. It currently starts at 20x20 tiles with 3 splits, adds 20x20 tiles and one split per level, and guards against `Vector2i` overflow using `MAX_VECTOR2I_COMPONENT`.
- `project.godot` defines a 640x360 logical viewport and a 1280x720 window override. The override scales presentation; it must not double dungeon dimensions.
- `procedural/proc_gen_world.gd` defines `TILE_SIZE = 16` and passes a level configuration's size, splits, and seed to generation.
- The player camera currently uses the default unit zoom. This feature does not change camera settings or reserve space for HUD elements.
- `Branch.split()` treats splits as recursive depth and creates `2^(splits + 1)` leaves. It has no minimum-room-size guard, so increasing splits on every size increase would be excessive.

## Progression rules

### Starting dimensions

Read `display/window/size/viewport_width` and `display/window/size/viewport_height` through `ProjectSettings`. Divide each by `ProcGenWorld.TILE_SIZE`, rounding up to whole tiles. The current settings produce `Vector2i(40, 23)`.

The dimensions describe the generator's nominal size, not guaranteed walkable area. Existing boundary-wall generation and camera following remain unchanged. At the current settings, rounding the height up covers 368 rather than 360 pixels.

Clamp the starting dimensions to the maximum as well. If a future configured viewport exceeds that maximum, the maximum takes precedence. Assume valid positive project viewport dimensions and tile size.

Resolve and retain the starting dimensions once per procedural run, including lazy initialization when a configuration is requested before an explicit start. Reset that snapshot with procedural progression. Existing configurations must not change when viewport settings change during a run.

### Growth and cap

For a valid one-based level index:

```text
growth_steps = (level_index - 1) / 2  # Integer division.
size.x = start_size.x + 5 * min(growth_steps, ceil((120 - start_size.x) / 5))
size.y = start_size.y + 5 * min(growth_steps, ceil((120 - start_size.y) / 5))
size = component_wise_min(size, Vector2i(120, 120))
```

Bound growth steps before multiplication, so even a very large valid level index cannot overflow intermediate size arithmetic. This replaces the need for `MAX_VECTOR2I_COMPONENT` and the size-overflow rejection branch. Continue rejecting indices below level 1.

Independent clamping intentionally changes the aspect ratio as one axis reaches its cap first. The last increment on an axis can be smaller than five tiles.

### Split lookup table

Select the last matching row using the final, clamped dungeon dimensions. Both dimensions must meet the row's minimum. Keep the table centralized in `ProceduralGameSession`; do not derive unbounded recursive depth from the level index.

| Minimum dimensions | Splits | BSP leaves |
| --- | --- | --- |
| Fallback for all sizes | 3 | 16 |
| 60x40 tiles | 4 | 32 |
| 100x80 tiles | 5 | 64 |

This is the proposed initial tuning. It changes splits only when size changes, grows split depth more slowly than dimensions, and caps it at 5. Validate these thresholds with representative seeds before accepting the feature. The table limits recursion but does not guarantee minimum room dimensions with the existing BSP algorithm. If generation checks expose a problem, adjust the table within this feature; algorithm changes require separate approval.

### Examples with current project settings

| Levels | Size in tiles | Splits |
| --- | --- | --- |
| 1-2 | 40x23 | 3 |
| 3-4 | 45x28 | 3 |
| 7-8 | 55x38 | 3 |
| 9-10 | 60x43 | 4 |
| 23-24 | 95x78 | 4 |
| 25-26 | 100x83 | 5 |
| 33-34 | 120x103 | 5 |
| 39-40 | 120x118 | 5 |
| 41 onward | 120x120 | 5 |

## Implementation phases

### Phase 1: Viewport-derived starting size

- Replace the fixed first-level size with a small session-owned calculation using project viewport settings and `ProcGenWorld.TILE_SIZE`.
- Retain the computed starting size for the run and clear it on reset, alongside existing progression state.
- Ensure referencing the tile-size constant does not introduce a script-loading dependency cycle. If necessary, pass the value at initialization without duplicating the constant or changing the generator.
- Add focused tests in `test/test_GameSession.gd` for 40x23 at current settings, upward rounding, independence from window overrides, snapshot stability, and reset/recalculation.
- Restore any modified project settings after tests.

### Phase 2: Every-second-level growth and bounded size

- Set the size increment to `Vector2i(5, 5)` and the growth interval to two levels.
- Introduce the configurable maximum `Vector2i(120, 120)` and clamp each axis independently.
- Bound arithmetic before multiplying growth steps; remove `MAX_VECTOR2I_COMPONENT`, its overflow calculations, and the obsolete overflow error path.
- Preserve invalid-index handling, nonzero random seeds, independent returned copies, lazy configuration creation, and per-run caching.
- Update session tests for paired levels, the first increase on level 3, partial-axis clamping, full clamping, a starting viewport above the cap, and very large valid indices.
- Replace any old overflow-rejection test with capped-size assertions.

### Phase 3: Size-based split lookup

- Replace the per-level split increment with the centralized table above, selected from final dungeon dimensions.
- Test both sides of each threshold, requiring both dimensions, plus saturation at the final row.
- Check the examples above, stable revisits, and reset behavior through the existing session API.
- Leave `DungeonGenerator`, `Branch`, and BSP subdivision behavior unchanged.

### Phase 4: Integration and tuning

- Update existing expectations in `test/test_ProcGenWorld.gd` that assume the previous size or split progression.
- Run focused session and procedural-world GUT tests, then the full suite using `test_ING.bat`.
- Exercise the existing generator through tests with representative fixed seeds at the starting size, both split thresholds, and maximum size. Check successful generation and usable distinct stair endpoints without modifying generation code.
- Manually play levels 1-3 and backtrack; check initial framing, stairs, and unchanged character/session state. Inspect representative threshold and capped dungeons without requiring a 41-level playthrough.
- Record generation time and room usability at the proposed lookup thresholds and cap. Tune only the table if necessary; do not claim a performance guarantee without measurements.
- Update the growth and acceptance statements in `feature_multiple_levels.md` to reference this feature and remove the superseded claim that every deeper level must be larger.

## Acceptance criteria

- With the current project settings, levels 1-2 use 40x23 tiles and levels 3-4 use 45x28 tiles.
- The starting size follows logical viewport settings and the shared tile-size constant, not the window override or runtime window dimensions.
- Starting dimensions remain stable for the run and are recalculated for a new run.
- Growth happens only on levels 3, 5, 7, and so on, with independent axis clamping and no dimension above 120 tiles.
- At current settings, width reaches 120 on level 33 and both dimensions reach 120 on level 41. Later levels remain valid and capped, including very large valid indices.
- Split depth follows the bounded size lookup table, with a maximum of 5, rather than increasing on every deeper level.
- `MAX_VECTOR2I_COMPONENT` and the obsolete size-overflow rejection are removed from procedural progression.
- Seeds, cached configuration copies, revisits, resets, transitions, and classic mode retain their existing behavior.
- No changes are made to `DungeonGenerator`, `Branch`, or the BSP algorithm.
- Focused tests and the full suite pass; manual checks and representative-seed generation checks are completed and any remaining tuning risks are recorded.