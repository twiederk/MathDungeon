# Feature: Surprise Attack

## Goal

When the player runs into an enemy **from the top or from behind**, the encounter counts as a
*surprise attack*: the enemy immediately loses 1 hit point, the quiz dialog shows the message
„Überraschungsangriff! −1 LP“ and plays a sound. For every other approach direction nothing
changes.

All enemy sprites currently face left, so "from behind" means **from the right**. An enemy can now
be flipped to face right; for such an enemy the surprise attack comes **from the top or from the
left**.

## Decisions

- The approach direction is determined inside `Enemy` when the player enters the `DetectionArea`
  and is passed outwards as an enum value (`NORMAL` / `SURPRISE`) through the `encountered` signal.
- The damage is applied by the **QuizDialog** (`enemy.hurt(1)`), not by `Enemy` itself. This keeps
  `Enemy` free of dialog/sound logic and makes the hit point loss visible in the already open
  dialog including the updated `EnemyStatsSheet`.
- `hurt(1)` internally computes `max(1, damage - armor)`, so a surprise attack always costs
  exactly 1 hit point regardless of armor. This is intentional.
- Decision rule: dominant axis of the offset between player and enemy position.
  - `abs(dx) > abs(dy)` → horizontal: surprise if the player stands **behind** the enemy, i.e. to
    the right for a left-facing enemy and to the left for a flipped one.
  - otherwise vertical: surprise if the player is **above** the enemy (independent of facing).
  - This assigns every diagonal unambiguously; approaching the enemy's front or from below gives
    no bonus.
- Facing is **not** a new exported flag. The existing `flip_h` property of the enemy's `Sprite2D`
  is the single source of truth: `Enemy` only reads it. Advantages:
  - the flip is immediately visible in the Godot editor (a `@export` applied in `_ready()` would
    only take effect at runtime, and making it editor-visible would require a `@tool` script),
  - no duplicated state that could drift apart from the rendered sprite.
  - Default stays `flip_h = false` → all existing enemies face left and keep the current
    behaviour.
- Projectiles (`projectile.gd`) can never be surprised — the projectile hits the player, not the
  other way round, so it always reports `NORMAL`. The `Enemy` that `projectile.gd` creates in code
  has no `DetectionArea` either, so the direction check never runs for it.

## Changes

### 1. `enemies/enemy.gd`

- Enum, extended signal and sprite reference:

  ```gdscript
  enum AttackType { NORMAL, SURPRISE }

  signal encountered(enemy: StaticBody2D, attack_type: AttackType)

  @onready var sprite: Sprite2D = $Sprite2D
  ```

- `_ready()` stays unchanged — nothing has to be applied, the sprite already renders the flip set
  in the scene.

- `_on_body_entered` determines the type:

  ```gdscript
  func _on_body_entered(body: Node) -> void:
      if body.name == "Player":
          encountered.emit(self, _attack_type_for(body))


  # Approaching from above or from the enemy's back surprises it.
  func _attack_type_for(player: Node2D) -> AttackType:
      var offset := player.global_position - global_position
      if absf(offset.x) > absf(offset.y):
          if _is_behind(offset.x):
              return AttackType.SURPRISE
          return AttackType.NORMAL
      if offset.y < 0.0:
          return AttackType.SURPRISE
      return AttackType.NORMAL


  # Sprites are drawn facing left, so a flipped sprite faces right.
  func _is_behind(horizontal_offset: float) -> bool:
      if sprite.flip_h:
          return horizontal_offset < 0.0
      return horizontal_offset > 0.0
  ```

- `hurt()` stays unchanged.
- The code-created `Enemy` in `projectile.gd` never enters the scene tree and never runs the
  direction check, so the missing `Sprite2D` child is harmless (`@onready` only resolves when the
  node enters the tree).

### 1b. Enemy scenes (`enemies/*.tscn`)

- No script changes needed. To make an enemy face right, tick `flip_h` on its `Sprite2D` node in
  the inspector — the editor shows the mirrored sprite right away and the surprise side follows
  automatically.
- If the sprite is not centered on the body, also check the `CollisionShape2D` / `DetectionArea`
  offsets after flipping.

### 2. `enemies/patrolling_enemy.gd`

- Update signal and forwarding (the connection in `patrolling_vindicator.tscn` stays unchanged,
  only the method signature changes):

  ```gdscript
  signal encountered(enemy: StaticBody2D, attack_type: Enemy.AttackType)

  func _on_enemy_encountered(a_enemy, attack_type) -> void:
      encountered.emit(a_enemy, attack_type)
  ```

- Facing: flip the `Sprite2D` of the embedded `Enemy` node inside the patrol scene (e.g.
  `patrolling_vindicator.tscn`) — same mechanism as for any other enemy. Dynamically flipping with
  the patrol direction is explicitly **out of scope**, because the back side would then change
  while the player is approaching.

### 3. `enemies/projectile.gd`

- Align the signature and always send `NORMAL`, because a projectile hits the player and can never
  be surprised:

  ```gdscript
  signal encountered(enemy: StaticBody2D, attack_type: Enemy.AttackType)
  ...
  encountered.emit(enemy, Enemy.AttackType.NORMAL)
  ```

- `enemies/shooting_enemy.gd` needs no change — it only connects `projectile.encountered` to
  `main_scene._on_enemy_encountered`.

### 4. `classic/world_level.gd`

- Pass the attack type through:

  ```gdscript
  func _on_enemy_encountered(enemy: StaticBody2D, attack_type: Enemy.AttackType) -> void:
      quiz.open_for(enemy, attack_type)
  ```

- `_setup_signals()` stays unchanged (`connect` does not depend on the signature).

### 5. `quiz/quiz_dialog.gd`

- `open_for` accepts the attack type and applies the surprise attack **after** the stats sheet has
  been set up, so the hit point display shows the deduction:

  ```gdscript
  const SURPRISE_DAMAGE: int = 1
  const SURPRISE_MESSAGE: String = "Überraschungsangriff! −1 LP"

  func open_for(my_enemy: Enemy, attack_type: Enemy.AttackType = Enemy.AttackType.NORMAL) -> void:
      enemy = my_enemy
      GameSession.display_state = GameSession.DisplayState.QUIZ_DIALOG
      _setup_exercise()
      _setup_time_limit_progress_bar()
      _setup_enemy_stats_sheet()
      if attack_type == Enemy.AttackType.SURPRISE:
          _apply_surprise_attack()
      visible = true
      answer_line_edit.grab_focus()
      get_tree().paused = true


  func _apply_surprise_attack() -> void:
      enemy.hurt(SURPRISE_DAMAGE)
      question_label.text = SURPRISE_MESSAGE + "\n" + exercise.question
      Sound.play(Sound.surprise_attack)
  ```

- Edge case: if the enemy has only 1 hit point left, the surprise attack drops it to 0 and
  `defeated` fires (loot is dropped via `world_level._on_enemy_defeated`). The dialog would still
  open with the next question. Handling: in `_apply_surprise_attack()` check whether
  `enemy.hit_points <= 0` and in that case run the regular victory path from `_answer_correct()`
  (score, `AchievementManager.track_enemy_defeat`, `enemy.queue_free()`, `_close_dialog()`)
  instead of asking a question. To do so, extract the victory block from `_answer_correct()` into
  a shared `_defeat_enemy()` method and call it from both places.

### 6. Sound

- `classic/sound.gd`: new export field

  ```gdscript
  @export var surprise_attack: AudioStream
  ```

- `classic/sound.tscn`: assign the field in the inspector. An existing hit sound is a good fit
  (e.g. `res://enemies/bow_shoot.ogg`); otherwise add a new file under `enemies/` and let it be
  imported.

## Tests (GUT, `test/`)

- Extend `test/test_Enemy.gd`:
  - player above → `encountered` with `Enemy.AttackType.SURPRISE` (both facings).
  - default enemy (`sprite.flip_h == false`): player to the right → `SURPRISE`, player to the left
    → `NORMAL`.
  - flipped enemy (`enemy.sprite.flip_h = true`): player to the left → `SURPRISE`, player to the
    right → `NORMAL`.
  - player below → `NORMAL`.
  - Verified via `watch_signals` + `get_signal_parameters(enemy, "encountered")`; the player can
    be simulated by a plain `Node2D` named `"Player"` placed at the desired position and passed
    directly to `enemy._on_body_entered()`.
  - `before_each` must add the enemy to the tree (`add_child_autofree`) so the `@onready sprite`
    is resolved before `flip_h` is set.
- Optional `test/test_QuizDialog.gd`: `open_for(enemy, SURPRISE)` reduces `enemy.hit_points` by
  exactly 1 and sets `question_label.text` with the „Überraschungsangriff! −1 LP“ prefix.

## Implementation Notes

- Run the tests after the changes with `cmd /c "test_ING.bat < nul"`.
- The signal change affects all `encountered` emitters/receivers; the list above is complete
  (`enemy.gd`, `patrolling_enemy.gd`, `projectile.gd`, `world_level.gd`).
