# Feature: 10 Minute Run

## Goal

Add a second game mode. In the **10 min run** mode the player starts a generic (proc gen) or
classic game and has 10 minutes to collect as many points as possible. When the time is up the
run ends immediately and the player can enter the highscore list — but into a **separate**
highscore list, so that normal games and 10 min runs never mix.

## Requirements

- New game mode toggle button in the start menu (`normal` / `10 min Lauf`), works like the
  switch-character / difficulty buttons: every press advances to the next mode.
- The game mode is stored in `GameSession` as an **enum**.
- New scene `countdown_timer_widget` (root node: `Control`) showing the remaining run time.
  It is displayed in all world scenes: `overworld`, `proc_gen_world`, `nether` and `end`.
- Separate highscore list for the 10 min run.

## Decisions

| Topic | Decision |
| --- | --- |
| End of run | Same flow as "player died": score entry dialog if it is a highscore, otherwise straight to the highscore screen. |
| Pausing | The countdown pauses whenever `GameSession.is_simulation_running()` is `false` (pause menu, quiz dialog, quest log, character sheet). |
| Widget in normal mode | Hidden completely. |
| Highscore storage | Second file `user://high_scores_10min`; `HighscoreManager` keeps one list per mode and selects it by the current game mode. |
| Highscore menu | New toggle button to switch between the two lists. |
| Duration | `const RUN_DURATION_SECONDS := 600.0` plus an overridable `run_duration_seconds` variable so tests can shorten it. |

---

## Phase 1 — Game mode in `GameSession`

**File:** `classic/game_session.gd`

- Add enum:
  ```gdscript
  enum GameMode {
      NORMAL,
      TIMED_RUN
  }
  ```
- Add `const RUN_DURATION_SECONDS := 600.0`.
- Add state:
  - `var game_mode: GameMode = GameMode.NORMAL`
  - `var run_duration_seconds: float = RUN_DURATION_SECONDS` (test override)
  - `var run_time_left: float = 0.0`
  - `var run_active: bool = false`
- Add signals:
  - `signal run_time_changed(seconds_left: float)`
  - `signal run_time_expired`
  - `signal game_mode_changed(mode: GameMode)`
- Add functions:
  - `is_timed_run() -> bool`
  - `toggle_game_mode()` — `NORMAL` → `TIMED_RUN` → `NORMAL` (plain `if`/`else`, no ternary).
  - `start_run()` — only in `TIMED_RUN`: `run_time_left = run_duration_seconds`, `run_active = true`,
    emit `run_time_changed`.
  - `stop_run()` — `run_active = false`.
- `reset()` keeps `game_mode` (it is a menu setting, not run state) but resets
  `run_time_left`/`run_active`, and calls `start_run()` is **not** done here — see Phase 3.
- `_process(delta)`:
  - return early if `not run_active` or `not is_timed_run()` or `not is_simulation_running()`
  - `run_time_left = max(0.0, run_time_left - delta)`
  - emit `run_time_changed(run_time_left)`
  - when it reaches `0.0`: `run_active = false`, emit `run_time_expired`

**Tests** (`test/test_GameSession.gd`)

- `toggle_game_mode` cycles `NORMAL` → `TIMED_RUN` → `NORMAL`
- `is_timed_run` reflects the mode
- `start_run` sets `run_time_left` to `run_duration_seconds` and activates the run
- `start_run` does nothing in `NORMAL` mode
- `_process` decreases `run_time_left`
- `_process` does not decrease while `display_state != NONE`
- `run_time_expired` is emitted once when the time reaches zero (`watch_signals` in arrange)
- `reset()` clears `run_time_left` / `run_active`
- `after_each()` restores `game_mode`, `run_duration_seconds`, `run_active`, `display_state`

---

## Phase 2 — Start menu toggle button

**Files:** `gui/start_menu.gd`, `gui/start_menu.tscn`

- Add `GAME_MODE_LABELS` dictionary next to `DIFFICULTY_LABELS`:
  ```gdscript
  const GAME_MODE_LABELS := {
      GameSession.GameMode.NORMAL: "Spielmodus: normal",
      GameSession.GameMode.TIMED_RUN: "Spielmodus: 10 min Lauf"
  }
  ```
- New `GameModeButton` in `CenterContainer/VBoxContainer`, placed directly below
  `DifficultyButton`, same theme/size as the other buttons, `pressed` connected to
  `_on_game_mode_button_pressed`.
- `@onready var game_mode_button: Button`
- `_on_game_mode_button_pressed()` → `GameSession.toggle_game_mode()` + `_update_game_mode_button()`
- `_update_game_mode_button()` → `game_mode_button.text = GAME_MODE_LABELS[GameSession.game_mode]`
- Call `_update_game_mode_button()` in `_ready()`.

**Tests** (`test/test_StartMenu.gd`, create if missing)

- button text matches the mode after `_update_game_mode_button()`
- pressing the button switches the mode and updates the label

---

## Phase 3 — Starting and ending the run

**Files:** `classic/world_level.gd`, `gui/start_menu.gd`

- Start menu: both `_on_start_game_button_pressed()` and `_on_start_generic_button_pressed()`
  call `GameSession.reset()` → `AchievementManager.reset()` → `GameSession.start_run()` before
  `change_scene_to_file()`.
  (The run therefore spans the whole session across nether/end transitions; `start_run()` is
  **not** called in `WorldLevel._ready()`.)
- `WorldLevel._ready()` connects `GameSession.run_time_expired` to `_on_run_time_expired()`.
- `_on_run_time_expired()` mirrors the game-over flow of `quiz/quiz_dialog.gd`:
  - `GameSession.display_state = GameSession.DisplayState.NONE`
  - `GameSession.stop_run()`
  - if `HighscoreManager.is_highscore(GameSession.score)` →
    `change_scene_to_file("res://gui/name_entry_dialog.tscn")`
  - else → `change_scene_to_file("res://gui/highscore_gui.tscn")`
- `nether.gd` and `proc_gen_world.gd` inherit this behaviour via `super._ready()` — verify both
  still call it.

**Tests** (`test/test_WorldLevel.gd`)

- `_on_run_time_expired()` stops the run
- target scene path selection: helper `_resolve_run_end_scene() -> String` so the decision is
  testable without a scene change; assert both branches by seeding `HighscoreManager`.

---

## Phase 4 — `countdown_timer_widget` scene

**Files:** `gui/countdown_timer_widget.gd`, `gui/countdown_timer_widget.tscn`

Modelled on `gui/score_widget.gd` / `.tscn`.

- Scene: `Control` root named `CountdownTimerWidget`, one `Label` child named `TimeLabel`,
  anchored top-center (below/next to the score widget, must not overlap `ScoreWidget`).
- Script:
  ```gdscript
  class_name CountdownTimerWidget
  extends Control
  ```
  - `_ready()`: connect `GameSession.run_time_changed` and `GameSession.game_mode_changed`,
    then `_update_visibility()` and `update_time()`
  - `_update_visibility()`: `visible = GameSession.is_timed_run()`
  - `update_time()`: `time_label.text = "Zeit: " + format_time(GameSession.run_time_left)`
  - `format_time(seconds: float) -> String` → `"%d:%02d" % [minutes, secs]` (ceil the seconds so
    the display never shows `0:00` while time is left)
  - Warning colour: turn the label red below 60 seconds remaining.

**Tests** (`test/test_CountdownTimerWidget.gd`)

- `format_time` for `600.0`, `59.4`, `0.0`
- widget is hidden in `NORMAL` mode and visible in `TIMED_RUN` mode

> After creating the new `class_name` script, run
> `Godot_v4.7-stable_win64.exe --path . --headless --import` once so the class cache / `.uid`
> is generated.

---

## Phase 5 — Embed the widget in the world scenes

**Files:** `classic/overworld.tscn`, `classic/nether.tscn`, `classic/end.tscn`,
`procedural/proc_gen_world.tscn`

- Instance `res://gui/countdown_timer_widget.tscn` into the existing `UI` `CanvasLayer` of each
  scene, next to `ScoreWidget`, node name `CountdownTimerWidget`.
- Check that it does not overlap `ScoreWidget` / `AchievementBadges` / `HealthMeterWidget`.

**Tests**

- `test/test_WorldScenes.gd`: instantiate each of the four world scenes and assert that
  `UI/CountdownTimerWidget` exists.

---

## Phase 6 — Separate highscore list per game mode

**File:** `classic/highscore_manager.gd`

- Replace the single `HIGHSCORE_PATH` by a path per mode:
  ```gdscript
  const HIGHSCORE_PATHS := {
      GameSession.GameMode.NORMAL: "user://high_scores",
      GameSession.GameMode.TIMED_RUN: "user://high_scores_10min"
  }
  ```
  (Keeps the existing normal file, so saved highscores are not lost.)
- Replace `var highscores: Array[Highscore]` by
  `var highscores_by_mode: Dictionary = {NORMAL: [], TIMED_RUN: []}`.
- Keep a `highscores` **property/getter** for the current mode so existing callers
  (`highscore_menu.gd`, tests) keep working, or update all call sites — decide during
  implementation, prefer explicit functions:
  - `get_highscores(mode := GameSession.game_mode) -> Array[Highscore]`
  - `is_highscore(score: int, mode := GameSession.game_mode) -> bool`
  - `add_score(player_name, score, difficulty_level, correct_answers, mode := GameSession.game_mode) -> bool`
- `_load_highscores()` / `_save_highscores(mode)` operate per mode; `_ready()` loads both files.
- `highscores_updated` keeps its current signature (the menu reloads the visible list).

**Tests** (`test/test_HighscoreManager.gd`)

- adding a score in `TIMED_RUN` does not appear in the `NORMAL` list and vice versa
- `is_highscore` evaluates against the list of the given mode
- both lists are capped at `MAX_HIGHSCORES` independently
- use temporary paths / restore the lists in `after_each()` so real user files are untouched

---

## Phase 7 — Highscore menu mode toggle

**Files:** `gui/highscore_menu.gd`, `gui/highscore_menu.tscn`

- New `ModeButton` above the `HighscoreContainer`, label from a
  `MODE_LABELS` dictionary (`"Bestenliste: normal"` / `"Bestenliste: 10 min Lauf"`).
- `var displayed_mode: GameSession.GameMode` initialised from `GameSession.game_mode` in
  `_ready()` so the player sees the list of the mode they last played.
- `_on_mode_button_pressed()` toggles `displayed_mode`, updates the button label and calls
  `_update_highscore_display()`.
- `_update_highscore_display()` uses `HighscoreManager.get_highscores(displayed_mode)`.
- Heading/empty text stays as is (`"Noch keine Einträge"`).

**Tests** (`test/test_HighscoreMenu.gd`)

- toggling `displayed_mode` switches between the two lists
- the initial `displayed_mode` equals `GameSession.game_mode`

---

## Phase 8 — Score entry for the run

**File:** `gui/score_entry_dialog.gd`

- `_submit_name()` passes the current mode:
  `HighscoreManager.add_score(player_name, GameSession.score, GameSession.difficulty_level, GameSession.correct_answers, GameSession.game_mode)`
  (works automatically if `mode` defaults to `GameSession.game_mode` — then no change is needed,
  just verify).
- Optional: show `"10 min Lauf"` in the dialog headline when `GameSession.is_timed_run()`.

---

## Phase 9 — Regression run

- `cmd /c "test_ING.bat < nul" > gut_out.txt 2>&1` and review the tail; delete `gut_out.txt`
  afterwards.
- Manual check:
  1. Start menu → toggle to `10 min Lauf` → start classic game → countdown visible and counting
     down, pauses during quiz/pause menu.
  2. Go through the nether portal → countdown continues, widget present.
  3. Shorten `run_duration_seconds` to verify the end-of-run flow and the separate highscore list.
  4. Toggle back to `normal` → countdown widget hidden, normal highscore list used.

---

## Out of scope

- No achievements specific to the 10 min run.
- No pause/extension items that add time.
- No change to the scoring rules themselves.
