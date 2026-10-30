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
- **Screen-space overlay, not world-attached**: fireworks celebrate a global
  event (reaching the top 10), not something that happens *to* a specific
  world entity. Attaching the effect to the player's `global_position` (as
  `Enemy._spawn_hit_effect()` does for hit impacts) was considered and
  rejected — if the burst is positioned in world space and the player walks
  away while it plays, the player would no longer see it, and it introduces an
  unwanted dependency from the effect on `Player`. Instead this follows the
  exact pattern already used by `quests/achievement_popup.tscn`: a `Control`/
  particle node added as a permanent child of each level scene's `UI`
  `CanvasLayer` (confirmed present in `overworld.tscn`, `nether.tscn`,
  `proc_gen_world.tscn`, `end.tscn`, each already parenting an `AchievementPopup`
  instance). A `CanvasLayer` child renders in fixed screen space regardless of
  camera/player movement, so the fireworks always stay visible on screen for
  their full duration.
  - The node connects to `GameSession.entered_highscores` itself in `_ready()`
    (same as `AchievementPopup` connecting to `AchievementManager.achievement_unlocked`),
    not via `Player` — no dependency on the player at all.
  - It stays permanently in the scene tree (like `AchievementPopup`) and toggles
    `visible`/`emitting` on trigger, rather than being dynamically instantiated
    and `queue_free()`d like `Enemy`'s hit effect — that spawn-and-destroy
    pattern fits per-instance world effects, not a single persistent screen
    overlay.

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

## Phase 3 — Fireworks effect scene (screen-space overlay)
3. **Create `gui/fireworks_effect.gd`** (`class_name FireworksEffect`,
   `extends Control`, mirroring `AchievementPopup`'s structure):
   ```gdscript
   class_name FireworksEffect
   extends Control


   func _ready() -> void:
       GameSession.entered_highscores.connect(_on_entered_highscores)


   func _on_entered_highscores() -> void:
       for burst: GPUParticles2D in _bursts():
           burst.emitting = true


   func _bursts() -> Array:
       return $Bursts.get_children()
   ```
   (No `queue_free()`/`finished` handling needed — the node stays in the tree
   permanently like `AchievementPopup`, simply re-triggering `emitting = true`
   if it were ever needed again, though `GameSession.has_entered_highscores`
   already guarantees this only fires once per run.)
4. **Create `gui/fireworks_effect.tscn`**
   - Root `Control` (full-rect anchors, `mouse_filter = MOUSE_FILTER_IGNORE` so
     it never blocks gameplay input/clicks — same consideration as any other
     `UI` overlay) with the script above.
   - A `Bursts` container node holding 2–3 `GPUParticles2D` children at varied
     screen-space offsets (e.g. upper-left/upper-right/top-center), each with
     its own `ParticleProcessMaterial` for a radial burst (`spread = 180`,
     `initial_velocity_min/max`, `gravity` pulling particles down, a
     `color_ramp` cycling through bright colors), `one_shot = true`,
     `explosiveness = 1.0`, `emitting = false` by default so nothing shows
     until triggered.

## Phase 4 — Wire into level scenes
5. **`classic/overworld.tscn`, `classic/nether.tscn`, `procedural/proc_gen_world.tscn`,
   `classic/end.tscn`**
   - Add `[ext_resource type="PackedScene" path="res://gui/fireworks_effect.tscn"]`
     and instance it as a child of the existing `UI` `CanvasLayer` node,
     directly alongside the existing `AchievementPopup` child in each scene
     (same parent, same layering — no new `CanvasLayer` needed since one
     already exists in every level scene).

## Phase 5 — Out of scope / follow-ups
- Sourcing a celebratory sound effect (e.g. from the local Minecraft installation,
  similar to how death sounds were sourced) to play alongside the fireworks —
  can be added later via `Sound.firework` + wiring in `fireworks_effect.gd`.
- Visual polish (custom firework textures/sprites instead of plain particle
  colors) — can replace the `GPUParticles2D` burst with textured particles later
  without changing the trigger logic in `GameSession`.

## Open Questions to Confirm Before Implementing
- None currently blocking — the screen-space `UI` `CanvasLayer` + permanent
  overlay approach directly mirrors `AchievementPopup`, which is already
  instanced identically across all four level scenes.
- Whether `test/test_GameSession.gd` already exists and what conventions it
  already follows for stubbing/resetting `HighscoreManager` state, to keep new
  tests consistent instead of introducing a new pattern.
