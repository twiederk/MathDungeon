# Feature: Simulation State Redesign

## Problem

Opening the quiz dialog calls `get_tree().paused = true`. The `Sound` autoload inherits
`PROCESS_MODE_PAUSABLE`, so all its `AudioStreamPlayer`s are suspended while the tree is paused:
a sound triggered inside the quiz (e.g. the surprise attack sound) is only audible **after** the
quiz is closed.

More generally, "the whole tree is paused except nodes marked `WHEN_PAUSED`" is the wrong default
for this game. What we actually want to stop is the **simulation** (player movement, enemies,
projectiles, companions), not the UI and not the audio. In addition the quest log currently does
not stop the simulation at all, so enemies keep moving while the player reads it.

## Goal

- `GameSession` knows whether the simulation is running.
- Simulation stopped ⇒ player cannot move, enemies/projectiles/companions do not move, their
  timers do not fire.
- UI, audio and the dialogs' own timers keep running.
- `get_tree().paused` is used by the ESC pause menu **only**.
- The quest log stops the simulation like the quiz dialog does.

## Decisions

- `simulation running` is **derived** from the existing `GameSession.display_state`, not a second
  independently managed flag: running ⇔ `display_state == DisplayState.NONE`. This makes an
  inconsistent state impossible.
- The simulation is stopped by setting `process_mode = PROCESS_MODE_DISABLED` on the simulation
  subtrees, not by guard clauses in every `_process`. This also stops `Timer` nodes inside those
  subtrees (shooting enemies' `FireTimer`), which guard clauses would miss.
- Frozen subtrees: `Player`, `Enemies`, `Companions`. `Items` are static pickups and
  `TileMapLayer` has no logic, so they stay untouched.
- The ESC pause menu keeps using `get_tree().paused`. It is the only owner of the real tree pause
  and additionally freezes UI animations, which is the desired "game fully stopped" feeling.
- `Sound` gets `PROCESS_MODE_ALWAYS` so sounds also play while the pause menu is open.
- The quest log hotkey stays blocked while the quiz dialog is open (unchanged behaviour of
  `QuestLogGui._process`).

## Changes

### 1. `classic/game_session.gd`

- New signal and query function; the existing `display_state` setter also emits the new signal:

  ```gdscript
  signal simulation_running_changed(running: bool)

  var display_state: int = DisplayState.NONE:
      set(value):
          if display_state == value:
              return
          display_state = value
          display_state_changed.emit(value)
          simulation_running_changed.emit(is_simulation_running())


  func is_simulation_running() -> bool:
      return display_state == DisplayState.NONE
  ```

- `reset()` already sets `display_state = DisplayState.NONE`, so the simulation is running again
  after a reset. No further change.

### 2. `classic/world_level.gd`

- Subscribe in `_setup_signals()` (or `_ready()`) and apply the process mode:

  ```gdscript
  GameSession.simulation_running_changed.connect(_on_simulation_running_changed)
  ```

  ```gdscript
  func _on_simulation_running_changed(running: bool) -> void:
      var mode := Node.PROCESS_MODE_INHERIT
      if not running:
          mode = Node.PROCESS_MODE_DISABLED
      player.process_mode = mode
      enemies_root.process_mode = mode
      companions_root.process_mode = mode
  ```

- `_ready()` must apply the current state once (`_on_simulation_running_changed(
  GameSession.is_simulation_running())`), because a level can be entered while a dialog state is
  still set.
- Projectiles are added via `get_parent().add_child(projectile)` in
  `enemies/shooting_enemy.gd`, i.e. below `Enemies`, so they are frozen together with their
  shooter. No change needed there.
- `procedural/`-based levels extend/instantiate `WorldLevel`, so they inherit the behaviour.

### 3. `quiz/quiz_dialog.gd`

- Remove all four `get_tree().paused` assignments (`open_for`, `_close_dialog`, `_game_over`
  paths). Setting `display_state` is now sufficient to stop the simulation.
- The dialog's own `AnswerTimer` / `ProgressTimer` are children of the dialog in the UI layer and
  keep running — the time limit works unchanged.

### 4. `quiz/quiz_dialog.tscn`

- `process_mode` back to `0` (`PROCESS_MODE_INHERIT`). `WHEN_PAUSED` would now stop the dialog
  during normal play.

### 5. `gui/pause_gui.gd` / `gui/pause_menu.gd` / `gui/pause_menu.tscn`

- No logic change: `PauseGui` keeps setting `get_tree().paused` when toggling `PAUSE_MENU`.
- `pause_menu.tscn` and `pause_gui.tscn` keep `process_mode = 2` (`WHEN_PAUSED`) so the menu
  stays operable.
- Note the double effect while the pause menu is open: `display_state == PAUSE_MENU` also marks
  the simulation as stopped (subtrees disabled) **and** the tree is paused. Both are released
  again when returning to `NONE`.

### 6. `quests/quest_log_gui.gd`

- No change. Toggling `display_state` to `QUEST_LOG` now automatically freezes the simulation.
- The quest log itself lives in the UI layer and stays interactive.

## Risks / Notes

- `PROCESS_MODE_DISABLED` also stops `Area2D` monitoring in the frozen subtrees. That is desired:
  while a dialog is open no new encounter can trigger. Encounters are only possible again after
  the dialog returns to `NONE`.
- Nodes that are disabled while a dialog is open do not receive `body_entered` for overlaps that
  started during the freeze; Godot re-evaluates the overlap when the node is re-enabled, so a
  player still standing in a detection area can trigger a new encounter right away. Verify in
  playtest that closing the quiz does not immediately re-open it for the same enemy (the enemy is
  freed on defeat, but a fled/undefeated enemy could).
- `AchievementPopup` and other UI nodes are unaffected and keep animating during quiz/quest log.
- Scene changes (`change_scene_to_file`) after game over: make sure `display_state` is reset to
  `NONE` on the way out, otherwise the next level starts with disabled subtrees. `GameSession.
  reset()` covers the normal flow; the game over buttons already set `display_state = NONE`.

## Tests (GUT, `test/`)

- `test/test_GameSession.gd`:
  - `is_simulation_running()` is `true` for `DisplayState.NONE` and `false` for `QUIZ_DIALOG`,
    `PAUSE_MENU`, `QUEST_LOG`.
  - `simulation_running_changed` is emitted with `false` when entering `QUIZ_DIALOG` and with
    `true` when returning to `NONE` (via `watch_signals`).
  - `reset()` leaves the simulation running.
- New `test/test_WorldLevel.gd` (or extend an existing level test): after
  `_on_simulation_running_changed(false)` the `Player`, `Enemies` and `Companions` nodes have
  `process_mode == Node.PROCESS_MODE_DISABLED`, and `PROCESS_MODE_INHERIT` after `true`.

## Manual Verification

1. Trigger a surprise attack → the sound is audible **immediately** while the quiz is open.
2. During the quiz: patrolling enemies stand still, shooting enemies fire no projectiles,
   companions stop following, the time limit bar still runs.
3. Open the quest log → simulation freezes; close it → everything resumes.
4. ESC during normal play → pause menu, everything frozen; sounds triggered by the menu are
   audible.
5. ESC during the quiz → ignored (unchanged).
