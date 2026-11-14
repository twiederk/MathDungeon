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

### Phase 1: Session-level configuration (implemented)

- `GameSession` tracks the current procedural level and stores each level's seed and size independently from the classic world seed.
- A new procedural run starts at level 1 with an 80x80 dungeon. Each deeper level grows by 20 tiles in each dimension.
- Level configurations are created lazily and remain stable during the session; invalid indices and `Vector2i` dimension overflow are rejected.
- `GameSession.reset()` clears procedural progression, and the procedural start-menu action initializes a new level-one configuration.
- Focused `GameSession` tests cover initialization, stable repeated access, size growth, and reset behavior; existing world-seed tests continue to pass.

### Phase 2: Room endpoints and deterministic generation (implemented)

- `Dungeon` now exposes start and end room positions, selected from the first and last BSP leaves in traversal order; coincident endpoints fall back to another distinct leaf center when available.
- `DungeonGenerator` accepts a level seed and seeds generation before BSP splitting, enemy selection, and item selection.
- `ProcGenWorld` resolves the current level's stored configuration and passes its size and seed into generation instead of using a fixed world size.
- Generator and world tests verify distinct endpoints are floor cells, the stored size is used, and identical seeds reproduce floor/wall layouts and enemy/item scenes and positions.

### Phase 3: Procedural stair scenes and transitions (implemented)

- Reusable stairs-up and stairs-down Area2D scenes use the existing art and a shared player-entry script.
- `ProcGenWorld` places stairs at the generated first- and last-room positions. Destination stairs remain disarmed until the player exits, preventing an immediate reverse transition on arrival.
- Descending increments the level and lazily creates its configuration; ascending below level one decrements the level and spawns at that level's down stairs. Transitions preserve `GameSession` and character state.
- Ascending from level one stops the run, sending qualifying scores to name entry and other scores directly to the main menu.
- Focused procedural-world tests cover stair placement, depth changes, both arrival positions, arrival-trigger behavior, and both run-ending routes.

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