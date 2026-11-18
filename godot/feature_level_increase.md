# Feature: Screen-Sized Procedural Level Progression

## Goal

Start procedural dungeons at approximately one logical screen, grow them gradually every second level, and cap their dimensions at a practical maximum. Keep BSP split depth reasonable through a small lookup table in the session progression code.

Phases 1-3 and the automated integration work in phase 4 are implemented. Manual gameplay and visual checks remain pending.

## Scope and decisions

- Apply only to procedural mode; classic mode remains unchanged.
- Use a fixed `FIRST_PROCEDURAL_LEVEL_SIZE = Vector2i(40, 23)`, based on the unchanged 640x360 logical viewport and 16-pixel tiles.
- Do not read viewport settings or calculate the starting size at runtime. Window resizing and window overrides do not affect dungeon dimensions.
- Levels 1 and 2 have the starting dimensions. Grow by `Vector2i(5, 5)` on levels 3, 5, 7, and so on.
- Clamp each dimension independently to `Vector2i(120, 120)`.
- Continue creating new levels and seeds after reaching the cap; only dimensions and split depth stop growing.
- Do not modify `DungeonGenerator`, `Branch`, or the BSP algorithm. Control the existing split argument through a lookup table instead.
- Preserve cached per-level configurations, deterministic revisits, reset behavior, stairs, and player/session state.

## Current implementation

- `classic/procedural_game_session.gd` owns procedural configuration creation and caching. It starts at a constant 40x23 tiles with 3 splits, grows by 5x5 every second level, clamps each axis at 120, and selects bounded split depth from the size lookup table. Growth is bounded before multiplication; the former `MAX_VECTOR2I_COMPONENT` guard is removed.
- `project.godot` defines a 640x360 logical viewport and a 1280x720 window override. The override scales presentation; it must not double dungeon dimensions.
- `procedural/proc_gen_world.gd` defines `TILE_SIZE = 16` and passes a level configuration's size, splits, and seed to generation.
- The player camera currently uses the default unit zoom. This feature does not change camera settings or reserve space for HUD elements.
- `Branch.split()` treats splits as recursive depth and creates `2^(splits + 1)` leaves. It has no minimum-room-size guard, so increasing splits on every size increase would be excessive.

## Progression rules

### Starting dimensions

Use `FIRST_PROCEDURAL_LEVEL_SIZE = Vector2i(40, 23)`. This matches the fixed 640x360 logical viewport divided by the 16-pixel tile size, rounded up to whole tiles. These settings are assumed not to change, so no runtime calculation or per-run snapshot is needed.

The dimensions describe the generator's nominal size, not guaranteed walkable area. Existing boundary-wall generation and camera following remain unchanged. At the current settings, rounding the height up covers 368 rather than 360 pixels.

The starting dimensions are below the maximum. If the viewport or tile size is intentionally changed in the future, update the constant explicitly.

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

This initial tuning passed the representative-seed checks below. It changes splits only when size changes, grows split depth more slowly than dimensions, and caps it at 5. The table limits recursion but does not guarantee minimum room dimensions with the existing BSP algorithm. If further checks expose a problem, adjust the table within this feature; algorithm changes require separate approval.

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

### Phase 1: Fixed screen-sized starting dimensions (implemented)

- Set `FIRST_PROCEDURAL_LEVEL_SIZE` to `Vector2i(40, 23)`.
- Use the constant for level-size calculations and retain existing session caching and reset behavior.
- Avoid runtime project-settings reads, per-run sizing state, and a dependency on `ProcGenWorld`.
- Validate with the existing focused session tests; no project-settings mutation tests are needed.

The initial dynamic-sizing implementation was simplified to a constant by request.

### Phase 2: Every-second-level growth and bounded size (implemented)

- Set the size increment to `Vector2i(5, 5)` and the growth interval to two levels.
- Introduce the configurable maximum `Vector2i(120, 120)` and clamp each axis independently.
- Bound arithmetic before multiplying growth steps; remove `MAX_VECTOR2I_COMPONENT`, its overflow calculations, and the obsolete overflow error path.
- Preserve invalid-index handling, nonzero random seeds, independent returned copies, lazy configuration creation, and per-run caching.
- Update session tests for paired levels, the first increase on level 3, partial-axis clamping, full clamping, and very large valid indices.
- Replace any old overflow-rejection test with capped-size assertions.

### Phase 3: Size-based split lookup (implemented)

- Replace the per-level split increment with the centralized table above, selected from final dungeon dimensions.
- Test both sides of each threshold, requiring both dimensions, plus saturation at the final row.
- Check the examples above, stable revisits, and reset behavior through the existing session API.
- Leave `DungeonGenerator`, `Branch`, and BSP subdivision behavior unchanged.

### Phase 4: Integration and tuning (automated checks complete)

- Update existing expectations in `test/test_ProcGenWorld.gd` that assume the previous size or split progression.
- Run focused session and procedural-world GUT tests, then the full suite using `test_ING.bat`.
- Exercise the existing generator through tests with representative fixed seeds at the starting size, both split thresholds, and maximum size. Check successful generation and usable distinct stair endpoints without modifying generation code.
- Manually play levels 1-3 and backtrack; check initial framing, stairs, and unchanged character/session state. Inspect representative threshold and capped dungeons without requiring a 41-level playthrough.
- Record generation time and room usability at the proposed lookup thresholds and cap. Tune only the table if necessary; do not claim a performance guarantee without measurements.
- The older `feature_multiple_levels.md` is absent from the current workspace and has not been recreated. This document defines the current progression and supersedes the earlier requirement for every deeper level to be larger.

## Verification results

- The focused session suite passes 37 test methods, including parameterized checks for 22 level indices and eight split-threshold cases. Coverage includes paired levels, independent axis clamping, the partial final height increment, capped-level caching, and the maximum signed 64-bit level index.
- Routine scene-level checks cover levels 1 and 3, verifying actual generated dimensions, recursive depth, distinct stairs on floor cells, and player arrival. Larger-level progression is covered by inexpensive session tests and direct generator tests rather than redundant full scene instantiation. A separate transition test travels 1 -> 2 -> 3 -> 2 -> 1 and verifies configuration reuse and unchanged character/session state.
- Routine generator checks use seed 4711 once at each size below and verify distinct stair endpoints on floor cells. A single small-dungeon regeneration check reproduces floor/wall layouts, stair positions, and enemy/item scenes and positions. These progression checks generate six dungeons instead of 24, without timing instrumentation or custom print output.
- The full suite, run with `test_ING.bat`, passes all 214 test methods across 34 scripts. Parameterized cases are counted within their test methods. Existing shutdown resource warnings remain; no generation algorithm changes were made.

Historical generator-only measurements from the initial four-seed tuning run on this machine (seeds 1, 42, 1234, and 4711). All 16 cases generated distinct stair endpoints on floor cells. This benchmark sweep is no longer part of routine tests:

| Size | Splits | Time across four seeds | Smallest leaf axis observed |
| --- | --- | --- | --- |
| 40x23 | 3 | 2.76-3.47 ms | 2 tiles |
| 60x40 | 4 | 14.01-15.64 ms | 2 tiles |
| 100x80 | 5 | 134.40-153.86 ms | 3 tiles |
| 120x120 | 5 | 402.74-440.51 ms | 4 tiles |

These are observations, not performance guarantees; scene instantiation and rendering add cost. The table remains unchanged because the sampled endpoint and determinism checks passed. Thin early leaves remain a known limitation of the unchanged BSP algorithm, and arbitrary seeds are not guaranteed to produce comfortably sized rooms.

### Remaining manual checks

- Play levels 1-3 and backtrack using the stairs, checking initial framing, physical traversal, and unchanged character/session state.
- Visually inspect representative split-threshold and capped dungeons for room usability and perceived transition time.
- Automated scene and transition tests do not replace these manual checks; they were not performed during this implementation.

## Acceptance criteria

- With the current project settings, levels 1-2 use 40x23 tiles and levels 3-4 use 45x28 tiles.
- The starting size is a fixed `Vector2i(40, 23)`, matching the assumed unchanged logical viewport and tile size.
- No runtime viewport calculation or per-run size snapshot is required; window overrides and resizing do not affect progression.
- Growth happens only on levels 3, 5, 7, and so on, with independent axis clamping and no dimension above 120 tiles.
- At current settings, width reaches 120 on level 33 and both dimensions reach 120 on level 41. Later levels remain valid and capped, including very large valid indices.
- Split depth follows the bounded size lookup table, with a maximum of 5, rather than increasing on every deeper level.
- `MAX_VECTOR2I_COMPONENT` and the obsolete size-overflow rejection are removed from procedural progression.
- Seeds, cached configuration copies, revisits, resets, transitions, and classic mode retain their existing behavior.
- No changes are made to `DungeonGenerator`, `Branch`, or the BSP algorithm.
- Focused tests and the full suite pass; manual checks and representative-seed generation checks are completed and any remaining tuning risks are recorded.