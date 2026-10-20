# Feature: Hit Effect

## Problem

A `HitEffect` scene (`enemies/hit_effect.tscn`, an `AnimatedSprite2D` driven by `enemies/effect.gd`)
should play whenever an enemy gets hurt. But while the quiz dialog is open, `GameSession.
display_state == QUIZ_DIALOG` and `WorldLevel` disables the `Enemies` subtree
(`PROCESS_MODE_DISABLED`, see `feature_simulation_redesign.md`). An `AnimatedSprite2D` only
advances its frames while it is actually processed, so a `HitEffect` instance parented under the
hurt `Enemy` (or anywhere else inside the disabled `Enemies` subtree) would never animate and
would stay frozen on its first frame until the dialog closes.

## Goal

The hit effect plays immediately at the enemy's position, every time `Enemy.hurt()` reduces its
hit points — both for a correct quiz answer and for a surprise attack — regardless of whether the
quiz dialog is currently open.

## Decision

Don't parent the effect under the enemy (or anything else inside `Enemies`/`Companions`/`Player`).
Instead, spawn it as a child of `get_tree().current_scene`, i.e. the `WorldLevel` root itself.

- `WorldLevel`'s root node already has `process_mode = PROCESS_MODE_ALWAYS` set in every level
  scene (`overworld.tscn`, `nether.tscn`, `procedural/proc_gen_world.tscn`, `end.tscn`), so a
  direct child keeps animating no matter what state `display_state` is in (`QUIZ_DIALOG`,
  `QUEST_LOG`, `PAUSE_MENU`).
- `get_tree().current_scene` is already used the same way in `enemies/shooting_enemy.gd`
  (`var main_scene = get_tree().current_scene`), so this is an established pattern in this
  codebase, not a new one.
- The effect's lifetime is fully decoupled from the enemy's: `Effect._on_animation_finished()`
  already calls `queue_free()` on itself once the one-shot animation ends. If the enemy is
  defeated and freed right after (`QuizDialog._defeat_enemy()`), the already-spawned effect is
  unaffected because it was never a child of the enemy.
- The alternative of overriding `process_mode` on the spawned effect node (as planned for the
  future "hurt" sprite animation in `feature_simulation_redesign.md`) is unnecessary here, because
  the effect is never inside a disabled subtree in the first place.
- No new signal / forwarding chain is needed. Routing this through `WorldLevel` (connecting a new
  `Enemy` signal the way `encountered`/`defeated` are wired in `_setup_signals()`) would additionally
  require fixing `PatrollingEnemy`, which currently forwards `encountered` but not `defeated` for
  its nested `Enemy` — out of scope for this feature. Spawning the effect directly inside
  `Enemy.hurt()` sidesteps that gap entirely and keeps the change in one file.

## Changes

### 1. `enemies/enemy.gd`

- Preload the effect scene and instantiate it in `hurt()`, alongside the existing hurt sound:

  ```gdscript
  const HIT_EFFECT_SCENE := preload("res://enemies/hit_effect.tscn")


  func hurt(damage: int) -> int:
      Sound.play(Sound.hurt)
      _spawn_hit_effect()
      hit_points -= max(1, damage - stats.get_armor())
      if hit_points <= 0:
          defeated.emit(self)
      return hit_points


  # Parented to the level root (not to this enemy) so it keeps animating even while
  # Enemies/Companions/Player are disabled during a dialog.
  func _spawn_hit_effect() -> void:
      var effect := HIT_EFFECT_SCENE.instantiate()
      effect.global_position = global_position
      get_tree().current_scene.add_child(effect)
  ```

- No change to `enemies/effect.gd`, `enemies/hit_effect.tscn`, `enemies/patrolling_enemy.gd`, or
  `enemies/projectile.gd`. The ephemeral `Enemy` created in `projectile.gd` for a projectile hit
  never calls `hurt()` (it sets `hit_points` directly), so it never spawns an effect — unchanged,
  out of scope.

## Risks / Notes

- `get_tree().current_scene` must be the `WorldLevel` instance for this to render in world space.
  True for all current play scenes (`overworld.tscn`, `nether.tscn`, procedurally generated
  dungeons, `end.tscn`); if a future scene change swaps `current_scene` to something without a 2D
  canvas (e.g. a pure UI scene) while an enemy is still hurt in the same frame, the effect would be
  parented to the wrong scene. Not a realistic case today since `hurt()` only runs while a
  `WorldLevel` is active and visible.
- The effect also keeps animating while the ESC pause menu is open (tree paused), because
  `PROCESS_MODE_ALWAYS` ignores `SceneTree.paused`. Given the animation is two frames long this is
  not noticeable and is accepted the same way `Sound` already behaves during pause.

## Tests (GUT, `test/`)

- Extend `test/test_Enemy.gd`: after calling `enemy.hurt(1)` (with the enemy added to the tree via
  `add_child_autofree`, so `get_tree().current_scene` resolves), assert that the scene tree gained
  one more child of type `Effect` than before. Exact position assertion is optional; checking the
  node count/type increase on `get_tree().current_scene` next frame is sufficient.
