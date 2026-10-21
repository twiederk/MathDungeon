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
Instead, spawn it as a child of the topmost ancestor of the enemy — the `WorldLevel` root in a
real level, the GUT test node in a unit test.

- `WorldLevel`'s root node already has `process_mode = PROCESS_MODE_ALWAYS` set in every level
  scene (`overworld.tscn`, `nether.tscn`, `procedural/proc_gen_world.tscn`, `end.tscn`), so a
  direct child keeps animating no matter what state `display_state` is in (`QUIZ_DIALOG`,
  `QUEST_LOG`, `PAUSE_MENU`).
- `get_tree().current_scene` looked like the obvious parent (it's already used the same way in
  `enemies/shooting_enemy.gd`), but `SceneTree.set_current_scene()` requires its argument to be a
  **direct child of `root`**. GUT test nodes are nested several levels under `root`, so assigning
  `current_scene` for a test fails with `Condition "p_scene && p_scene->get_parent() != root" is
  true` and `current_scene` stays `null`, in turn making `enemy.hurt()` crash in any test. Walking
  up the enemy's own ancestor chain instead works both in a real level (where it resolves to the
  same `WorldLevel` node that `current_scene` would have pointed to, because `change_scene_to_file`
  always parents the new scene directly under `root`) and inside a unit test (where it resolves to
  whatever node the test added the enemy under).
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
      _effect_parent().add_child(effect)


  # Topmost ancestor (the level root in-game, the test node in unit tests), so the
  # effect's parent is never inside this enemy's own, possibly disabled, subtree.
  func _effect_parent() -> Node:
      var node: Node = self
      while node.get_parent() != null and node.get_parent() != get_tree().root:
          node = node.get_parent()
      return node
  ```

- No change to `enemies/effect.gd`, `enemies/hit_effect.tscn`, `enemies/patrolling_enemy.gd`, or
  `enemies/projectile.gd`. The ephemeral `Enemy` created in `projectile.gd` for a projectile hit
  never calls `hurt()` (it sets `hit_points` directly), so it never spawns an effect — unchanged,
  out of scope.

## Risks / Notes

- `_effect_parent()` relies on `change_scene_to_file` always parenting the active `WorldLevel`
  directly under `root` — true today for every play scene (`overworld.tscn`, `nether.tscn`,
  procedurally generated dungeons, `end.tscn`). If a `WorldLevel` were ever nested one level
  deeper (e.g. wrapped in another container scene), the effect would still end up on that
  container instead of `root`'s direct child — harmless as long as the container also keeps
  `PROCESS_MODE_ALWAYS` or inherits it.
- The effect also keeps animating while the ESC pause menu is open (tree paused), because
  `PROCESS_MODE_ALWAYS` ignores `SceneTree.paused`. Given the animation is two frames long this is
  not noticeable and is accepted the same way `Sound` already behaves during pause.

## Tests (GUT, `test/`)

- Extend `test/test_Enemy.gd`: after calling `enemy.hurt(1)` (with the enemy added to the tree via
  `add_child_autofree`, so `get_tree().current_scene` resolves), assert that the scene tree gained
  one more child of type `Effect` than before. Exact position assertion is optional; checking the
  node count/type increase on `get_tree().current_scene` next frame is sufficient.
