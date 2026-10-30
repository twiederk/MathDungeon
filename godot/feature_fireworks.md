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
- **Synergy with `enemies/effect.gd`**: the project already has a reusable
  one-shot effect pattern — `Effect` (`enemies/effect.gd`, extends `AnimatedSprite2D`)
  plays an animation and `queue_free()`s itself when finished, instanced on
  demand via `Enemy._spawn_hit_effect()` (`HIT_EFFECT_SCENE.instantiate()`,
  positioned at `global_position`, added via `_effect_parent()` which walks up
  to a safe top-level node under `get_tree().root`). The fireworks effect
  should follow this exact same spawn-and-self-destroy pattern instead of being
  permanently embedded in every level scene like `achievement_popup.tscn`:
  - A new `FireworksEffect` class (`extends GPUParticles2D`) mirrors `Effect`:
    connect to its own `finished` signal (emitted once when a `one_shot`
    particle system completes) with `CONNECT_ONE_SHOT` and `queue_free()`.
  - It is instantiated dynamically (preloaded scene, like `HIT_EFFECT_SCENE`)
    and spawned at the player's `global_position` when
    `GameSession.entered_highscores` fires, reusing the same "walk up to a
    safe top-level parent" logic as `Enemy._effect_parent()`.
  - `Player` (`classic/player.gd`) is the natural trigger point: it already
    exists exactly once per level scene with a valid `global_position`, unlike
    `GameSession` (an autoload, no position) or `achievement_popup` (a fixed UI
    overlay, not world-positioned).
  - This avoids touching `overworld.tscn`, `nether.tscn`, `proc_gen_world.tscn`,
    and `end.tscn` at all — no permanent node needs to be added to any level
    scene.

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

## Phase 3 — Shared `effects/` folder + safe-parent helper
3. **Create the `effects/` folder** and move:
   - `enemies/effect.gd` → `effects/effect.gd`
   - `enemies/hit_effect.tscn` → `effects/hit_effect.tscn`
   - `enemies/hit_effect.png` (+ `.import`) → `effects/hit_effect.png`
   Update `uid://`-based `ext_resource` paths inside `hit_effect.tscn` and the
   two preload sites (`enemies/enemy.gd`, `characters/character.gd`) to
   `res://effects/...`. Re-run `--headless --import` after moving.
4. **Extract a shared safe-parent helper**, e.g. `effects/effect_spawner.gd`
   (`class_name EffectSpawner`, a small autoload-free static-style utility, or
   a `static func` directly on a new tiny class):
   ```gdscript
   class_name EffectSpawner


   static func spawn(effect_scene: PackedScene, at: Node2D) -> void:
       var effect := effect_scene.instantiate()
       effect.global_position = at.global_position
       _safe_parent(at).add_child(effect)


   static func _safe_parent(node: Node) -> Node:
       var current := node
       while current.get_parent() != null and current.get_parent() != current.get_tree().root:
           current = current.get_parent()
       return current
   ```
   - Replace `Enemy._spawn_hit_effect()`/`_effect_parent()` with a call to
     `EffectSpawner.spawn(HIT_EFFECT_SCENE, self)`.
   - Replace `Character._spawn_hit_effect()`'s `current_scene`-based lookup with
     the same call, fixing the pre-existing test-unsafe code path as a side
     effect (confirm with the user before changing `Character`'s behavior,
     since it's outside this feature's direct scope — flagged below).
   - `Player` will use `EffectSpawner.spawn(FIREWORKS_EFFECT_SCENE, self)` too.
5. **Create `effects/fireworks_effect.gd`** (`class_name FireworksEffect`,
   `extends GPUParticles2D`):
   ```gdscript
   class_name FireworksEffect
   extends GPUParticles2D


   func _ready() -> void:
       finished.connect(queue_free, CONNECT_ONE_SHOT)
       emitting = true
   ```
   (`GPUParticles2D.finished` only fires when `one_shot = true`, set on the
   particle node itself in the scene — see below.)
6. **Create `effects/fireworks_effect.tscn`**
   - Root `GPUParticles2D` (`one_shot = true`, `explosiveness = 1.0`) with the
     script above.
   - 2–3 child `GPUParticles2D` nodes (or sibling emitters under the root, each
     with its own `ParticleProcessMaterial`) positioned at slightly different
     offsets/delays, each configured for a radial burst (`spread = 180`,
     `initial_velocity_min/max`, `gravity` pulling particles down, a
     `color_ramp` cycling through bright colors) to mimic a short multi-burst
     fireworks show. All child emitters must also be `one_shot = true` so the
     root's `finished` signal only fires after every burst completes.

## Phase 4 — Spawn the effect from `Player`
7. **`classic/player.gd`**
   - Add `const FIREWORKS_EFFECT_SCENE := preload("res://effects/fireworks_effect.tscn")`.
   - In `_ready()`, connect `GameSession.entered_highscores.connect(_on_entered_highscores)`.
   - Add `_on_entered_highscores()`: call `EffectSpawner.spawn(FIREWORKS_EFFECT_SCENE, self)`.

## Phase 5 — Out of scope / follow-ups
- Sourcing a celebratory sound effect (e.g. from the local Minecraft installation,
  similar to how death sounds were sourced) to play alongside the fireworks —
  can be added later via `Sound.firework` + wiring in `fireworks_effect.gd`.
- Visual polish (custom firework textures/sprites instead of plain particle
  colors) — can replace the `GPUParticles2D` burst with textured particles later
  without changing the trigger logic in `GameSession`.

## Open Questions to Confirm Before Implementing
- Whether changing `Character._spawn_hit_effect()` to use the new shared
  `EffectSpawner` helper (fixing its test-unsafe `current_scene` usage) is
  acceptable as part of this feature, or should be left untouched/done as a
  separate follow-up change, since it's not strictly required to implement
  fireworks (only `Enemy` and the new `Player` call site strictly need it).
- Whether `test/test_GameSession.gd` already exists and what conventions it
  already follows for stubbing/resetting `HighscoreManager` state, to keep new
  tests consistent instead of introducing a new pattern.
