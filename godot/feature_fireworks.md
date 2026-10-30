# Feature: Fireworks on Entering Top 10 Highscores

## Goal
When the player earns points (`GameSession.add_score()`) and that score newly
qualifies for the top 10 highscores (`HighscoreManager.is_highscore(score)`),
play a fireworks animation once per game session.

## Scope / Decisions
- The check happens only at `GameSession.add_score()` call sites (enemy defeat,
  achievement bonus) — not on every `score_changed` emission in general, since
  `add_score()` is the only place score actually increases.
- "Once" means once per game session/run: a flag is reset in `GameSession.reset()`
  (new game), so a new run can trigger fireworks again.
- The firework visual is a built-in `GPUParticles2D` burst — no external sprite/
  particle texture asset needed.
- The effect follows the same pattern as `quests/achievement_popup.tscn`: a scene
  added as a child to each level root scene (`overworld.tscn`, `nether.tscn`,
  `proc_gen_world.tscn`, `end.tscn`), reacting to a global signal in `_ready()`.

## Phase 1 — GameSession: track & signal "entered top 10"
1. **`classic/game_session.gd`**
   - Add `signal entered_highscores`.
   - Add `var has_entered_highscores: bool = false`.
   - In `reset()`, add `has_entered_highscores = false`.
   - In `add_score(points: int)`, after `score += points`, add:
     ```gdscript
     if not has_entered_highscores and HighscoreManager.is_highscore(score):
         has_entered_highscores = true
         entered_highscores.emit()
     ```
   - Keep `AchievementManager.track_score(score)` call as-is, after this check
     (order doesn't matter functionally, but keep existing line last for a
     minimal diff).

## Phase 2 — Tests for `GameSession`
2. **`test/test_GameSession.gd`** (create if it doesn't exist yet — check first)
   - `test_add_score_emits_entered_highscores_when_score_qualifies`: arrange
     `HighscoreManager.highscores` so a low score (e.g. `0`) qualifies (empty
     list or below `MAX_HIGHSCORES` entries), `watch_signals(GameSession)`, act
     `GameSession.add_score(10)`, assert `entered_highscores` emitted.
   - `test_add_score_does_not_emit_entered_highscores_twice`: call
     `add_score()` twice (both qualifying), assert `entered_highscores` was
     emitted exactly once (`assert_signal_emit_count(GameSession, "entered_highscores", 1)`).
   - `test_add_score_does_not_emit_entered_highscores_when_score_does_not_qualify`:
     arrange `HighscoreManager.highscores` with 10 entries all scoring higher
     than the test score, act `add_score()`, assert not emitted.
   - `test_reset_clears_entered_highscores_flag`: set `has_entered_highscores = true`
     via a qualifying `add_score()` call, act `reset()`, assert a subsequent
     qualifying `add_score()` emits `entered_highscores` again.
   - Arrange/cleanup: save & restore `HighscoreManager.highscores` and
     `GameSession` state in `before_each`/`after_each` (both are autoloads with
     persistent state across tests — follow the existing pattern used in other
     tests that touch `GameSession`/`HighscoreManager`, e.g. resetting
     `difficulty_level`, `highscores` list, etc. Check `test/test_HighscoreManager.gd`
     and `test/test_quiz_dialog.gd` for the established setup/teardown style
     before writing these).

## Phase 3 — Fireworks effect scene
3. **Create `gui/fireworks_effect.gd`** (`class_name FireworksEffect`, `extends Node2D`
   or `Control` depending on how it needs to be positioned — likely `Node2D`
   anchored to the player or screen-center, consistent with how other level-root
   children are positioned; confirm by checking how `achievement_popup` is
   anchored/positioned inside `overworld.tscn` before deciding).
   - `_ready()`: connect to `GameSession.entered_highscores`.
   - On signal: trigger one or more `GPUParticles2D` bursts (`emitting = true`,
     `one_shot = true`), optionally staggered with short `await get_tree().create_timer(...).timeout`
     calls for a multi-burst "fireworks show" effect.
   - Optionally play a sound via `Sound.play(...)` if a suitable firework/
     celebratory sound is added later (out of scope for now — see Phase 5).
4. **Create `gui/fireworks_effect.tscn`**
   - Root `Node2D`/`Control` with the script above.
   - 2–3 `GPUParticles2D` children, each configured with a `ParticleProcessMaterial`
     for a radial burst (`direction`, `spread = 180`, `initial_velocity_min/max`,
     `gravity` pulling particles down, `scale_amount`, `color_ramp` cycling
     through a few bright colors per particle system to mimic distinct firework
     colors), `one_shot = true`, `explosiveness = 1.0`, `amount` tuned for a
     dense/short burst.
   - Position particle children at varied offsets (e.g. top area of the screen)
     so multiple bursts appear at different spots.

## Phase 4 — Wire into level scenes
5. **`classic/overworld.tscn`, `classic/nether.tscn`, `procedural/proc_gen_world.tscn`,
   `classic/end.tscn`**
   - Add `[ext_resource type="PackedScene" path="res://gui/fireworks_effect.tscn"]`
     and instance it as a child node, mirroring exactly where/how
     `achievement_popup.tscn` is added in each of these scenes (same parent
     container, similar z-index/layering so it renders above gameplay but
     doesn't block input — check `achievement_popup`'s parent node and CanvasLayer
     usage, if any, before placing).

## Phase 5 — Out of scope / follow-ups
- Sourcing a celebratory sound effect (e.g. from the local Minecraft installation,
  similar to how death sounds were sourced) to play alongside the fireworks —
  can be added later via `Sound.firework` + wiring in `fireworks_effect.gd`.
- Visual polish (custom firework textures/sprites instead of plain particle
  colors) — can replace the `GPUParticles2D` burst with textured particles later
  without changing the trigger logic in `GameSession`.

## Open Questions to Confirm Before Implementing
- Exact node type/parent and CanvasLayer usage for `achievement_popup.tscn` in
  each level scene needs to be inspected before building `fireworks_effect.tscn`
  layout, to keep the fireworks visually consistent (e.g. same UI layer so it
  isn't hidden behind tile layers).
- Whether `test/test_GameSession.gd` already exists and what conventions it
  already follows for stubbing/resetting `HighscoreManager` state, to keep new
  tests consistent instead of introducing a new pattern.
