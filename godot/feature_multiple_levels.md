# Feature: Multiple Procedural Dungeon Levels

## Goal

Allow the player to travel between procedurally generated dungeon levels. Each deeper level is larger than the previous one. Stair scenes connect levels, and a level's seed and size remain stable for the lifetime of the game session so revisiting it recreates the same dungeon.

This feature applies only to procedural mode. Classic mode and its world transitions remain unchanged.

## Intended behavior

- Start a procedural run on the smallest dungeon level.
- Give each level a stable level index, random seed, and dungeon size, retained in `GameSession` for the whole run.
- Increase dungeon dimensions as the player progresses deeper. Keep the growth rule centralized and configurable.
- Place stairs up in the first room and stairs down in the last room of every generated dungeon.
- Stairs down moves to the next deeper level. Stairs up on levels below the first returns to the preceding level.
- Climbing stairs up on the first level ends the procedural run. If the score qualifies as a highscore, let the player enter a name to save it; otherwise return directly to the main menu. Follow the existing timed-run end flow for stopping the run and highscore submission, with the specified main-menu destination for a non-highscore.
- Going back to a visited level recreates it with the same seed and size; preserving defeated enemies, collected items, or prior player position is not required.
- Keep player character state and run/session data when changing procedural levels.

## Current implementation context

- `procedural/proc_gen_world.gd` creates one fixed `Vector2i(100, 100)` dungeon and resolves its seed from `GameSession.world_seed`.
- `procedural/dungeon_generator.gd` builds a BSP tree and uses its leaf rooms, but exposes only a start position; it does not identify a last room or stair positions.
- `procedural/dungeon.gd` is the generated dungeon data container.
- `classic/game_session.gd` currently stores one world seed and is shared by both game modes.
- Procedural art files `procedural/stairs_up.png` and `procedural/stairs_down.png` exist; there are no corresponding procedural stair scenes yet.

## Proposed session model

Add procedural-level state to `GameSession`, separate from the existing classic world seed. Store an entry per level index containing at minimum:

- `seed`: the seed used to generate that level.
- `size`: the `Vector2i` dimensions passed to dungeon generation.

Track the current procedural level index as well. Provide small session methods to initialize/reset procedural progression, get-or-create a level's configuration, and move to an adjacent level. Avoid using the classic `world_seed` as the per-level seed store.

Create the first level's configuration when a procedural run starts. Create each deeper level's configuration the first time that level is reached, then retain it until the run is reset. This supports unbounded progression without preallocating an infinite list.

## Implementation phases

### Phase 1: Session-level configuration

- Add current procedural level index and a per-level configuration collection to `GameSession`.
- Add initialization/reset and get-or-create APIs for level seed and size.
- Define the initial dimensions and a centralized size-growth rule, including safeguards against invalid or impractically large dimensions.
- Ensure starting a new procedural run clears old progression and creates the first level's configuration, while entering/revisiting deeper levels preserves or lazily creates their configurations.
- Add `GameSession` tests for initialization, stable configurations on repeated access, increasing dimensions by depth, and reset behavior. Verify classic world-seed behavior remains intact.

### Phase 2: Room endpoints and deterministic generation

- Extend `Dungeon` with explicit start-room and end-room positions for stair placement.
- Have `DungeonGenerator` choose those positions from generated leaf rooms using a stable rule (for example, first and last leaves in a documented traversal order); ensure they are distinct when the dungeon has multiple rooms.
- Pass the stored level size and seed through `ProcGenWorld` into `DungeonGenerator` instead of hard-coding the size.
- Keep all random dungeon generation reproducible from the level seed, including enemies and items where the generation flow uses randomness.
- Add generator/world tests proving endpoint validity, dimensions are honored, and identical level configurations produce identical room/floor layouts.

### Phase 3: Procedural stair scenes and transitions

- Create reusable procedural stairs-up and stairs-down scenes using the existing stair art and a clear interaction/collision area consistent with the project's other location scenes.
- Place stairs up at the first-room position and stairs down at the last-room position when `ProcGenWorld` builds the level.
- Connect stair activation to procedural level navigation. Deeper progression increments the level index; stairs up below level one decrements it. Set the destination spawn to the paired stair position and change scenes without resetting the session or character.
- On level one, stairs up ends the run: stop active run state, send qualifying scores to the existing name-entry flow, and send non-qualifying scores directly to the main menu.
- Add focused tests for stair destinations, level index changes, retained per-level configurations, spawn positions on downward travel and backtracking, and both run-ending score outcomes.

### Phase 4: Integration and regression checks

- Verify procedural mode initializes progression on a new run and that existing start-menu routing still enters procedural mode correctly.
- Verify ascending from level one ends the run and routes to name entry for a highscore or the main menu otherwise.
- Verify changing levels does not reset score, character stats/inventory, companions, or timed-run state.
- Verify classic mode transitions and its existing single-world seed behavior are unaffected.
- Run the focused GUT tests, then the full project test suite; manually play a short procedural run through at least two levels and backtrack.

## Acceptance criteria

- A new procedural run begins on the smallest configured level.
- Each newly reached deeper level has larger dimensions than its predecessor.
- Every level has stairs up in its first room and stairs down in its last room.
- Stairs down reaches the next deeper level; stairs up returns to the preceding level below level one.
- Stairs up on level one ends the run, allowing highscore entry when eligible and returning to the main menu otherwise.
- A revisited level has the same seed, size, layout, and stair locations as before.
- Player/session state survives level transitions, and classic mode is unchanged.

## Confirmed decisions

- Progression is unbounded; create and store each level's seed and size on first visit.
- Level one is the bottom of the run. Climbing its stairs up ends the run; save a qualifying highscore through the name-entry flow, otherwise show the main menu.
- Deterministic regeneration from the stored seed and size is sufficient when revisiting a level; do not persist a level's full live state.