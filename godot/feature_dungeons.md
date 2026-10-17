# Feature: Counting Dungeon Quest

## Goal

The `dungeon` quest currently maps to a one-shot achievement and is marked as completed after
the very first cleared dungeon, even though the player can conquer many dungeons. Instead the
quest should count cleared dungeons and show the progress in the quest log exactly like the
`eyes_of_ender` quest does, e.g. `"1 / 4"`.

## Decisions

- Progress display reuses the existing eyes-of-ender mechanics: `"<cleared> / 4"`,
  capped at the target.
- Target is a fixed constant of **4** dungeons.
- The quest completes (green, `✔`) once 4 dungeons are cleared — same behaviour as
  `eyes_of_ender`.
- The counter accumulates across worlds (overworld, nether, procedural); every cleared dungeon
  increments it, no matter where it was found.
- The existing repeatable `dungeon` achievement ("Dungeon gesäubert!", +500 points per dungeon)
  stays untouched, so the player keeps getting the badge and bonus for every single dungeon.

## Changes

### 1. `quests/achievement_manager.gd`

- Add a new counting achievement next to the repeatable one, analogous to `eyes_4`/`eyes_8`/`eyes_12`:

  ```gdscript
  "dungeon_4": Achievement.new("Dungeon-Meister", "Erobere 4 Dungeons", 4, "dungeon",
          "conquere_dungeon.png", 2000),
  ```

  - Same `type` (`"dungeon"`), so `_check_progress_achievements("dungeon")` already feeds it
    through the existing `_track_location_defeat` → `progress["dungeon"] += 1` path.
  - Not `repeatable` → unlocks exactly once at 4.
- Add `"dungeon": 0` to the initial `progress` dictionary and to `reset()`, so the quest log
  starts at `0 / 4` and the counter is cleared on reset.
- No other logic changes; `_location_to_type()` already maps `dungeon_0`, `dungeon_1`, … to the
  shared `"dungeon"` type.

### 2. `quests/quest_log.gd`

- Point the dungeon quest at the new achievement and adjust the wording to the new target:

  ```gdscript
  Quest.new("dungeon", "Erobere 4 Dungeons", "Besiege alle Bewohner von 4 Dungeons.", "dungeon_4"),
  ```

- `get_status`, `get_progress` and `has_progress_bar` need **no** changes — with
  `target == 4` the quest automatically gets a counter and completes at 4.

### 3. `quests/quest_row.gd` / `quests/quest_log_gui.gd`

- No changes. `progress_label` already renders `"%d / %d"` for every quest with `target > 1`,
  and the bonus text picks up the new achievement's bonus automatically.

### 4. Badge / popup

- No changes. `conquere_dungeon.png` is reused for the new achievement; the popup shows
  "Dungeon-Meister" when the 4th dungeon is cleared, in addition to the per-dungeon popup.
- Check `quests/achievement_badges.gd` once: if badges are keyed by `badge_graphic`, the
  reused graphic may need the same de-duplication the eyes-of-ender tiers already use.

## Tests

### `test/test_QuestLog.gd`

1. `test_dungeon_quest_shows_progress`
   → clear 1 dungeon, `get_progress(dungeon) == Vector2i(1, 4)`, `has_progress_bar` is `true`.
2. `test_dungeon_quest_completes_after_four_dungeons`
   → clear 4 dungeons, `get_status` is `COMPLETED`.
3. `test_dungeon_quest_progress_is_capped`
   → clear 5 dungeons, `get_progress(dungeon) == Vector2i(4, 4)`.
4. `test_reset_reopens_the_dungeon_quest`
   → after `AchievementManager.reset()`, status is `OPEN` and progress is `Vector2i(0, 4)`.

Helper for clearing dungeons in tests: `AchievementManager.register_locations([...])` with enemy
doubles (`location = "dungeon_0"`, `"dungeon_1"`, …) and then `track_enemy_defeat(...)`,
analogous to the existing tests in `test/test_AchievementManager.gd`.

### `test/test_AchievementManager.gd`

5. `test_four_dungeons_unlock_the_dungeon_master_achievement`
   → `"dungeon_4" in unlocked_achievements` after the 4th dungeon, not before.
6. Verify the existing repeatable `dungeon` achievement still unlocks once per dungeon
   (existing tests must stay green).

## Not affected

- Score bonus and badge per single dungeon (`dungeon` achievement).
- Save games (`save_manager.gd`) — `progress["dungeon"]` is handled like the other counters.

## Verification

- Run `cmd /c "test_ING.bat < nul"`; all GUT tests green.
- Manual: open the quest log → dungeon quest shows `0 / 4`; after each cleared dungeon the
  counter increases; at `4 / 4` the row turns green with `✔` and the hint disappears.
