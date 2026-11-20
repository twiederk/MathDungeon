# Feature: World Level Entry Title

## Goal

Display the current world's name briefly when a world level loads, similar to the location-name reveal in Zelda games. Fade the title in, hold it for a few seconds, then fade it out automatically while gameplay continues.

Status: Phases 1-3 are implemented with focused automated verification. Titles are connected to world loading. Phase 4 full-suite and manual visual checks remain pending.

## Scope and proposed behavior

- Apply to classic worlds and procedural dungeon levels, not menus or other non-world scenes.
- Show the title once per scene load, including returning through portals, descending stairs, and ascending to a previously visited level.
- Start the reveal after world setup completes. Procedural generation, player placement, and UI initialization must finish first.
- Use a screen-space overlay, independent of player position, camera movement, and camera zoom.
- Fixed scene-authored timing: 0.4-second fade-in, 2.5-second hold, and 0.6-second fade-out. Edit the animation in the scene to change timing; do not expose duration variables or create or modify tracks programmatically.
- Do not pause gameplay, block input, change simulation state, or delay transitions. The title must not take keyboard focus or intercept mouse input.
- Let the animation follow normal scene-tree pause behavior. Do not introduce an always-processing node or change existing pause rules.
- Remove all visible title content after the animation. Leaving a level early must dispose of its overlay and animation without affecting the next scene.
- Use existing fonts, colors, and label styling. Center the title horizontally and vertically in the screen, with safe margins and clear of the HUD. Render it behind modal dialogs such as the quiz; this refers to draw order, not screen position.
- Keep text readable over both sand and dirt using the existing theme's outline or shadow treatment. Do not add a full-screen dimmer or a decorative panel.
- Respect the 640x360 logical viewport and window scaling. Use a fixed label width in logical pixels and disable wrapping so titles stay on one line. Keep the width unchanged when the title text changes, and verify the longest configured title fits without overlapping other UI.

## Existing implementation anchors

- `classic/world_level.gd`: `WorldLevel._ready()` performs shared world initialization and is the intended entry-title trigger.
- `classic/classic_world.gd`: `ClassicWorld._ready()` calls the base implementation before applying the player portrait. Check this ordering when selecting the final trigger point.
- `procedural/proc_gen_world.gd`: `ProcGenWorld._ready()` generates the dungeon before calling `super._ready()`, so the shared hook can show a title after generation.
- Classic world scenes and `procedural/proc_gen_world.tscn` already contain a `UI` CanvasLayer suitable for a reusable overlay.
- `classic/dungeon_title.gd` and its scene already display area-triggered location titles through an AnimationPlayer. Leave that scene and script unchanged. The world-entry title will use a new, independent scene and script, not an instance of or an inherited version of `classic/dungeon_title.tscn`.
- Existing GUT coverage lives in `test/test_WorldLevel.gd` and `test/test_ProcGenWorld.gd`.

## Title ownership

- Add an exported `world_title: String` to `WorldLevel` for authored world names.
- Add a `get_world_title() -> String` method that returns the authored value unchanged, including whitespace. Empty titles are skipped by presentation without an error or placeholder.
- Override the method in `ProcGenWorld` to derive a title from `GameSession.get_procedural_level_index()`. Do not cache a separate title in `LevelConfig` or progression state.
- Proposed classic titles, matching the game's existing German location labels: `Oberwelt`, `Nether`, `Das Ende`, and `Antike Stadt`.
- Proposed procedural format: `Ebene %d`, producing `Ebene 1`, `Ebene 2`, and so on. Resolve the index on arrival so backtracking displays the correct level.
- Treat these names as initial content choices, editable without changing overlay behavior. Do not derive player-facing names from scene filenames or dungeon IDs.

## Implementation phases

### Phase 1: Title data and resolution (implemented)

- Add the exported title property and resolver to `WorldLevel`.
- Assign explicit titles in `classic/overworld.tscn`, `classic/nether.tscn`, `classic/end.tscn`, and `classic/ancient_city.tscn`.
- Add the procedural resolver override using the current one-based session index.
- Extend the existing world tests to cover authored titles, empty titles, and procedural titles for levels 1, 2, and a return to level 1.
- Exit criterion: each world resolves the intended display text without changing progression, terrain, or scene transitions.

Verification: The focused WorldLevel and ProcGenWorld suites passed all 22 test methods (106 assertions) during phase 1 implementation, including authored scene titles, procedural levels 1 and 2, and returning to level 1. Existing floor alternation and transition tests also passed. The resolver now preserves whitespace, with updated expectations for whitespace-only and padded titles. Existing shutdown resource warnings remain. Full-suite and visual checks are deferred to phase 4.

### Phase 2: Reusable animated overlay (implemented)

- Create a new, independent reusable Control scene at `gui/world_level_title.tscn` with its own script at `gui/world_level_title.gd`.
- Give the new scene its own screen-centered, fixed-width Label with wrapping disabled and an AnimationPlayer for fade-in, hold, and fade-out. Match the game's existing typography and colors, but do not share or modify the existing dungeon-title scene, script, or animations. Keep the title initially hidden to avoid an editor-text flash.
- Do not add an Area2D, CollisionShape2D, or body-entered trigger. World-load integration will start the reveal explicitly through the component's presentation method.
- Keep `show_title(text: String)` to two statements: assign the label text and call `animation_player.play("reveal")`. Do not add guards, explicit resets, or forced animation advancement.
- Use normal AnimationPlayer playback: calling again during the reveal updates the text without restarting the active animation. Empty input is assigned unchanged; the world-load caller will skip empty titles in phase 3.
- Author initial opacity and visibility in the scene, and control showing and hiding through the fixed animation tracks. Ensure both the root Control and label ignore mouse input and cannot take focus.
- Connect `animation_finished` to a handler that calls `queue_free()`. The title instance is used once per world load and cannot be reused after completion.
- Add focused component tests for initial invisibility, supplied text, repeated playback, empty input, and deletion after completion. Prefer advancing the animation directly over waiting several seconds in tests.
- Exit criterion: the component can be exercised independently and reliably disappears after its configured sequence.

Implementation: `WorldLevelTitle` uses its own Control scene, a centered 560x48 logical-pixel Label with no wrapping, 24-pixel text with a black outline, and fixed scene-authored opacity and visibility tracks. `show_title(text)` only assigns the supplied text and plays `reveal`. Fade-in, hold, and fade-out take 0.4, 2.5, and 0.6 seconds. There are no guards, explicit resets, duration variables, or runtime track changes. The scene connects animation completion to a handler that calls `queue_free()`. Text clipping prevents overflow from resizing the label. The existing dungeon-title scene and script are unchanged.

Historical verification: All eight component test methods passed (42 assertions), covering initial invisibility, input/focus settings, supplied text, empty input, text updates during playback, intermediate fade values, final hiding, queued and actual deletion after completion, fixed scene-authored key timing, and fixed-width centering at 640x360 and 1280x720. Godot import completed. The component test script and its UID companion were subsequently deleted by request; they have not been recreated. Current integration coverage is in the existing WorldLevel and ProcGenWorld test scripts.

### Phase 3: World-load integration (implemented)

- Instantiate the component under each world's existing `UI` CanvasLayer, using the same node name and layout everywhere.
- Add one shared presentation hook at the end of `WorldLevel._ready()` after its existing setup. Confirm derived-class setup does not require deferring the reveal until the next frame.
- Resolve the title once per arrival and pass it to the overlay. Do not trigger it from `generate_world()`, `_process()`, or player collision events.
- Skip empty titles in the world-load caller before invoking `show_title()`; the component itself has no empty-text guard.
- Preserve tests that construct `WorldLevel.new()` without a full scene: resolve an optional overlay safely and skip presentation when no UI exists.
- Preserve procedural tests that deliberately suppress `_ready()` and invoke `generate_world()` explicitly; generation alone should not start a reveal.
- Keep the overlay below modal UI and clear of stats and countdown widgets. Retain existing area-triggered `DungeonTitle` behavior, and explicitly check for competing text at spawn points.
- If a spawn immediately activates an existing area title, let the local-location title take priority by dismissing the world-entry title through world-level coordination with the existing trigger signal. Leave the existing dungeon-title scene and script unchanged; do not introduce a global title queue.
- Exit criterion: every real world scene shows exactly one entry reveal after setup, including portal returns and procedural backtracking, without blocking play.

Implementation: All four classic worlds and the procedural world instance `UI/WorldLevelTitle` before the quiz and other UI siblings. `WorldLevel._ready()` calls `_show_world_title()` once after shared setup, using the existing title resolver. Empty titles or missing overlays skip presentation. Procedural generation finishes before the base setup; classic portrait and Nether visit setup finish synchronously before the next frame draws, so no deferred reveal is needed. Existing local-title `animation_started` signals dismiss the entry title through world-level coordination, with a fresh node lookup that remains safe after its completion callback frees it. The local-title scene/script and the two-statement `show_title()` method are unchanged.

Verification: All 24 focused WorldLevel and ProcGenWorld test methods pass (125 assertions). Coverage includes authored classic scene metadata and modal sibling order, title presentation and empty titles, missing UI, local-title priority before and after entry-title deletion, procedural arrivals at levels 1 and 2, returning from below, and silent direct generation with automatic setup suppressed. Existing progression, terrain alternation, player placement, and stair-transition checks also pass. Existing shutdown resource warnings remain. Manual portal and stair playthroughs, visual HUD/modal checks, and full-suite validation are pending in phase 4.

### Phase 4: Verification and visual tuning

- Extend existing world tests to verify the load hook supplies the resolved title once and that scenes without a title remain silent.
- Verify procedural generation still produces the same layouts and uses sand on odd levels and dirt on even levels. This feature must not modify generation or terrain selection.
- Add one scene-level integration check for the shared hook and reuse existing procedural scene tests for dynamic title coverage. Avoid duplicating expensive full-world generation solely to test text formatting.
- Verify repeated calls during playback update the text without stacking playback, completion frees the one-shot title instance, and unloading a scene mid-animation safely disposes of the component.
- Run focused GUT checks in the existing WorldLevel and ProcGenWorld scripts, then the full suite with `test_ING.bat`. Do not recreate the deleted standalone title test script.
- Manually enter each classic world; travel procedural levels 1 -> 2 -> 3 -> 2 -> 1; verify the correct title appears on every arrival and fully disappears.
- Check the logical 640x360 viewport and a scaled window, long titles, both floor terrains, camera movement, quiz dialogs, countdown visibility, and any area-title trigger near an arrival point.
- Record automated results separately from manual checks. Do not mark visual verification complete based only on passing tests.
- Exit criterion: acceptance criteria pass and remaining visual or timing concerns are documented.

## Acceptance criteria

- Loading any configured world displays its intended title automatically after setup.
- Procedural arrivals display the current level index correctly, including revisits.
- The title fades in, remains readable for a few seconds, fades out, and leaves no visible content behind.
- Empty titles produce no placeholder or animation.
- The overlay is screen-centered, uses a fixed label width with no wrapping, is readable at the supported viewport sizes, and does not obstruct critical HUD or modal UI. The longest configured title fits on one line without changing the label width.
- Player controls, combat, quizzes, timers, simulation state, and level transitions retain their current behavior.
- Repeated presentation does not stack animations, and scene changes safely discard an active reveal.
- Existing area-triggered location titles continue to work and do not compete with entry titles at arrival points.
- Focused and full automated tests pass, with manual visual checks recorded before declaring the feature complete.

## Out of scope

- New location discovery rules, title history, map UI, subtitles, or generated location names.
- Audio cues, cinematics, camera movement, gameplay freezes, and transition loading screens.
- Changes to dungeon generation, floor alternation, save data, or session progression.
- Refactoring all existing local-location title triggers into a new notification framework.