# Display State Coordination Plan

## Goal

Make the quiz dialog, pause menu, and quest log mutually exclusive. Keep the game paused for the quiz dialog and pause menu, but keep gameplay running while the quest log is open.

## Expected behavior

- Opening a quiz dialog hides or prevents the pause menu and quest log.
- While a quiz dialog is open, pause and quest-log inputs do not open their overlays.
- Opening the pause menu closes the quest log first.
- Pressing the pause key while the quest log is open closes the log and opens the pause menu in one key press.
- Opening the quest log is allowed only when neither the quiz dialog nor pause menu is active.
- Closing an overlay returns the display state to “none”; resuming from the pause menu unpauses the tree.

## Proposed design

Replace the quiz-only visibility flag as the coordination mechanism with a single authoritative active-display state in `GameSession`. Represent the possible states as `NONE`, `QUIZ_DIALOG`, `PAUSE_MENU`, and `QUEST_LOG`, and expose a change signal or explicit transition methods so UI nodes update visibility from the shared state rather than independently deciding which overlay to show.

Keep pause ownership explicit: opening or closing the quiz dialog and pause menu controls `SceneTree.paused`; the quest log never changes it. The pause controller should handle the quest-log-to-pause transition by setting the active state to `PAUSE_MENU`, which causes the quest log to hide before/while the pause menu is shown.

## Implementation steps

1. Add the display-state enum, authoritative state, and state-change notification or transition methods to `classic/game_session.gd`.
2. Update `gui/pause_gui.gd` to request the pause transition, hide its menu for all other states, and maintain the existing pause/unpause behavior.
3. Update `gui/quest_log_gui.gd` to show and hide in response to the shared state. Allow the quest-log input to toggle only between `NONE` and `QUEST_LOG`.
4. Update `quiz/quiz_dialog.gd` so all open, close, main-menu, and name-entry paths enter and leave `QUIZ_DIALOG` consistently.
5. Update `gui/pause_menu.gd` scene-exit behavior if necessary so leaving gameplay clears the active display state as well as unpausing.
6. Update `feature_quest_log.md` to document the shared display-state coordination and the pause-key transition.
7. Add focused tests for `GameSession` state transitions and run the relevant existing tests plus a Godot parse/load check.

## Verification criteria

- The active state changes correctly on each overlay open and close path.
- Quiz dialog and pause menu continue to pause the tree; quest log does not.
- Pause pressed while the quest log is visible results in only the pause menu being visible and the tree paused.
- Neither pause nor quest log can become visible during the quiz dialog.
- Returning to ordinary gameplay leaves the state at `NONE`.
- Existing score, quest progress, and pause-menu resume/exit behavior remain unchanged.
