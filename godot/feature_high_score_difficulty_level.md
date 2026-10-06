# Feature: Difficulty Level in High Scores

## Goal

Store the run's `GameSession.difficulty_level` with every new high score and show it in an
additional column in the high-score menu. Existing high scores must continue to load unchanged;
their difficulty cells remain empty because the old records do not contain this field.

## Current State

- `GameSession.difficulty_level` is an enum with `NORMAL` and `HARD` values. `GameSession.reset()`
  preserves it for the current run.
- `gui/score_entry_dialog.gd` submits scores through `HighscoreManager.add_score()`. Both
  `name_entry_dialog.tscn` and `victory_dialog.tscn` use this script.
- `classic/highscore_manager.gd` saves an array of JSON dictionaries containing `name`, `score`,
  and `date` to `user://high_scores`.
- `gui/highscore_menu.gd` builds each row dynamically. There is currently no column-header row.

## Decisions

| Topic | Decision |
|---|---|
| Stored field | Add `difficulty_level` to each new high-score dictionary |
| Stored representation | Use stable string values (`normal` / `hard`), not enum ordinals, so changing enum ordering cannot reinterpret saved scores |
| Capture point | Pass the active `GameSession.difficulty_level` from the shared score-entry script when submitting |
| Legacy records | Do not migrate or rewrite old entries on load; missing `difficulty_level` renders as an empty string |
| Menu label | Add a difficulty column with localized values matching the start menu (`normal` / `schwer`) |

## Implementation Phases

### Phase 1 — Persist difficulty on new scores

- Update `HighscoreManager.add_score()` to accept the difficulty for the run and include its stable
  string value in the new entry dictionary.
- Update `ScoreEntryDialog._submit_name()` to pass `GameSession.difficulty_level` when adding the
  score. This covers both score-entry scenes because they share this script.
- Leave `_load_highscores()` compatible with existing dictionaries. Do not require or inject a
  difficulty key while loading; old entries are retained as-is when the file is saved again.

### Phase 2 — Display the additional column

- Add a header row to the dynamically generated high-score list, including a difficulty heading.
- Add a difficulty label to each score row and read it with a missing-key default of `""`, so old
  entries display a genuinely empty cell rather than a placeholder.
- Map recognized stored values to the menu's localized labels (`normal` and `schwer`). Render an
  unknown or absent value as empty rather than failing to display the rest of the row.
- Keep the row and header column order aligned: player, score, date, difficulty.

### Phase 3 — Tests and verification

- Add focused GUT coverage for new score entries persisting both difficulty values.
- Cover loading or rendering a legacy entry without `difficulty_level`; verify it remains valid and
  its difficulty cell is empty.
- Verify an entry with a stored difficulty displays the corresponding localized label.
- Run the GUT suite with `test.bat` (or its Godot command without the final `pause`) and manually
  inspect the high-score menu with both a legacy entry and newly submitted scores.

## Acceptance Criteria

1. A newly submitted high score records the difficulty active for that run.
2. The high-score menu shows a difficulty column and the correct localized difficulty for new
   entries.
3. Existing high-score JSON remains loadable without migration, and entries with no difficulty
   display a blank cell.
4. Scores, dates, ranking, and the existing score-entry flows continue to work.