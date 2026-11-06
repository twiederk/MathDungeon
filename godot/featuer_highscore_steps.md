# Feature: Highscore Rank Widget

## Goal

Show the player's live rank in the highscore list as an on-screen widget (like `ScoreWidget` /
`CountdownTimerWidget`). Whenever the rank changes, the `FireworksEffect` plays and the widget
updates.

Displayed text:

| Situation            | Text           |
| -------------------- | -------------- |
| Outside the list     | `Kein Bestwert`|
| Rank 10              | `10. Rang`     |
| Rank 5               | `5. Rang`      |
| Rank 1               | `1. Rang`      |

## Decisions

- `GameSession.entered_highscores` is **replaced** by `highscore_rank_changed(rank: int)`.
  Fireworks fire on every rank improvement, not only on first entry.
- Rank calculation lives in `HighscoreManager.get_rank(score, mode) -> int`, `0` means "no rank".
- Ties: a new score ranks **below** an already stored equal score.
- Rank basis: the live `GameSession.score` is compared against the currently saved list; the rank is
  the position the score would take if it were added now. Only ranks `1..MAX_HIGHSCORES` count.
- Widget is visible in both `NORMAL` and `TIMED_RUN` mode.
- Placement: top-right, below `ScoreWidget` and above `AchievementBadges`, in `ancient_city.tscn`,
  `overworld.tscn`, `nether.tscn`, `end.tscn` and `procedural/proc_gen_world.tscn`.

## Affected files

- `classic/highscore_manager.gd` — new `get_rank()`.
- `classic/game_session.gd` — new signal, rank tracking, `reset()`.
- `gui/fireworks_effect.gd` — listen to the new signal.
- `gui/highscore_rank_widget.gd` / `.tscn` — new widget.
- `classic/ancient_city.tscn`, `classic/overworld.tscn`, `classic/nether.tscn`, `classic/end.tscn`,
  `procedural/proc_gen_world.tscn` — add widget instance.
- `test/test_HighscoreManager.gd`, `test/test_GameSession_Highscore.gd`,
  `test/test_HighscoreRankWidget.gd` (new).

---

## Phase 1 — `HighscoreManager.get_rank()`

1. Add to `classic/highscore_manager.gd`:

   ```gdscript
   const NO_RANK: int = 0

   func get_rank(score: int, mode: GameSession.GameMode = GameSession.game_mode) -> int:
       var highscores: Array = highscores_by_mode[mode]
       var rank: int = 1
       for entry in highscores:
           if score > entry.score:
               break
           rank += 1
       if rank > MAX_HIGHSCORES:
           return NO_RANK
       return rank
   ```

   The stored list is already sorted descending, so counting entries with `entry.score >= score`
   gives the "below equal scores" tie rule.

2. Optionally express `is_highscore()` via `get_rank() != NO_RANK` (behaviour stays identical).

3. Tests in `test/test_HighscoreManager.gd`:
   - empty list → rank `1`
   - score higher than all entries → rank `1`
   - score equal to the entry on rank 3 → rank `4`
   - full list, score lower than the last entry → `NO_RANK` (`0`)
   - partially filled list, lowest score → next free rank
   - ranks are evaluated per `GameMode` (mirrors existing mode tests)

**Done when:** all `HighscoreManager` tests pass.

---

## Phase 2 — `GameSession` rank tracking

1. In `classic/game_session.gd`:
   - Remove `signal entered_highscores` and `var has_entered_highscores`.
   - Add:

     ```gdscript
     signal highscore_rank_changed(rank: int)

     var highscore_rank: int = HighscoreManager.NO_RANK
     ```

   - In `add_score()` replace the `has_entered_highscores` block with:

     ```gdscript
     var new_rank := HighscoreManager.get_rank(score)
     if new_rank != highscore_rank:
         highscore_rank = new_rank
         highscore_rank_changed.emit(highscore_rank)
     ```

   - In `reset()` set `highscore_rank = HighscoreManager.NO_RANK` instead of
     `has_entered_highscores = false`.

2. Update `test/test_GameSession_Highscore.gd`:
   - rename tests to `highscore_rank_changed`
   - signal emitted with rank `1` when the score qualifies
   - signal **not** emitted again when the rank does not change
   - signal **not** emitted when the score does not qualify (full list, low score)
   - signal emitted again with an improved rank when the score climbs past another entry
   - `reset()` clears `highscore_rank` and the next qualifying score emits again

**Done when:** `GameSession` highscore tests pass; no reference to `entered_highscores` or
`has_entered_highscores` remains (`grep`).

---

## Phase 3 — `FireworksEffect` reacts to rank changes

1. In `gui/fireworks_effect.gd`:

   ```gdscript
   func _ready() -> void:
       GameSession.highscore_rank_changed.connect(_on_highscore_rank_changed)

   func _on_highscore_rank_changed(rank: int) -> void:
       if rank == HighscoreManager.NO_RANK:
           return
       Sound.play(Sound.firework)
       for burst: GPUParticles2D in bursts.get_children():
           burst.emitting = true
   ```

   Falling out of the list (only possible after a `reset()`/mode switch) must not trigger fireworks.

2. Test (`test/test_FireworksEffect.gd`, new or extend existing): emitting
   `highscore_rank_changed(1)` sets `emitting` on all bursts; emitting `NO_RANK` does not.

**Done when:** fireworks play on every rank improvement.

---

## Phase 4 — `HighscoreRankWidget`

1. New `gui/highscore_rank_widget.gd`:

   ```gdscript
   class_name HighscoreRankWidget
   extends Control

   const NO_RANK_TEXT := "Kein Bestwert"

   @onready var rank_label: Label = $RankLabel

   func _ready() -> void:
       GameSession.highscore_rank_changed.connect(_on_highscore_rank_changed)
       update_rank()

   func _on_highscore_rank_changed(_rank: int) -> void:
       update_rank()

   func update_rank() -> void:
       rank_label.text = format_rank(GameSession.highscore_rank)

   func format_rank(rank: int) -> String:
       if rank == HighscoreManager.NO_RANK:
           return NO_RANK_TEXT
       return "%d. Rang" % rank
   ```

2. New `gui/highscore_rank_widget.tscn`, modelled on `gui/score_widget.tscn`: root `Control` with
   the script, child `Label` named `RankLabel`, right-aligned anchors (`anchors_preset = 1`,
   `layout_direction = 1`), placeholder text `1. Rang`.

3. Run the headless import once so `class_name` and the `uid` are registered:
   `Godot_v4.7-stable_win64.exe --path . --headless --import`.

4. `test/test_HighscoreRankWidget.gd`:
   - `format_rank(0)` → `"Kein Bestwert"`
   - `format_rank(1)` → `"1. Rang"`
   - `format_rank(5)` → `"5. Rang"`
   - `format_rank(10)` → `"10. Rang"`
   - instantiating the scene and emitting `highscore_rank_changed` updates `RankLabel.text`

**Done when:** widget tests pass.

---

## Phase 5 — Scene integration

1. Add the widget instance under the `UI` node, ordered **after** `ScoreWidget` and **before**
   `AchievementBadges`, in:
   - `classic/ancient_city.tscn`
   - `classic/overworld.tscn`
   - `classic/nether.tscn`
   - `classic/end.tscn`
   - `procedural/proc_gen_world.tscn`

2. Layout per scene: same right-aligned anchors as `ScoreWidget`, offset downwards by roughly one
   line height so it sits between the score and the achievement badges.

3. Re-run `--headless --import` after hand-editing the `.tscn` files so the new `uid://` reference
   resolves (otherwise GUT reports "invalid UID").

**Done when:** running each level shows the rank widget below the score.

---

## Phase 6 — Verification

1. Run the full suite: `cmd /c "test_ING.bat < nul" > gut_out.txt 2>&1`, then inspect and delete
   `gut_out.txt`.
2. Manual check:
   - Fresh profile (empty list): first scored points → fireworks + `1. Rang`.
   - Full list, low score: widget shows `Kein Bestwert`, no fireworks.
   - Climbing from rank 10 to rank 9 → fireworks + updated text.
   - Starting a new game resets the widget text.
3. Verify `NORMAL` and `TIMED_RUN` use their own lists (rank follows `GameSession.game_mode`).
