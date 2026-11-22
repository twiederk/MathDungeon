# Feature Plan: World Level Title Color

## Goal

Display the Nether world title in red while keeping the existing appearance and reveal animation for all other worlds. Make the title color configurable on each instance of the shared world level title scene.

## Current Behavior

- `WorldLevel._ready()` passes the configured world title text to `WorldLevelTitle.show_title()`.
- `gui/world_level_title.tscn` displays the text in `TitleLabel`. Its `reveal` animation changes `TitleLabel.self_modulate.a`, toggles visibility, and frees the title after the animation finishes.
- The Nether, Overworld, End, Ancient City, and procedural worlds use instances of this shared title scene. The Nether instance currently has no color override.

## Proposed Approach

- Add an exported `Color` property to `WorldLevelTitle`, defaulting to white, so it can be configured on each scene instance in the inspector.
- In `show_title()`, apply the configured RGB channels to the label's `self_modulate` while preserving its current alpha, before starting `reveal`. The animation remains responsible for alpha; the color property's alpha is not used.
- Set the Nether's `UI/WorldLevelTitle` instance to opaque red. Leave the other instances at the default white tint and keep the existing outline, text, animation timings, and cleanup unchanged.

## Implementation Phases

### Phase 1: Configurable Title Color

- Export the color in `gui/world_level_title.gd` and apply its RGB channels when showing a title, without changing `show_title()`'s existing text argument or animation tracks.
- Check manually that the default white tint and a custom color display correctly throughout the reveal and fade-out.

### Phase 2: Nether Configuration

- Set the exported property to red on the `WorldLevelTitle` instance in `classic/nether.tscn`.
- Verify the packed Nether scene contains the red override and representative other world instances retain the default white tint. Do not change their world title text or the separate dungeon title.

### Phase 3: Integration and Validation

- Check the Nether in game: the world title is red, fades in and out on the existing schedule, and disappears after the animation. Check a non-Nether world and a procedural world retain their existing title appearance and behavior.
- Confirm the title still receives the correct text and frees itself after the animation finishes.

## Acceptance Criteria

- The Nether world title appears red throughout its reveal and fade-out.
- Each world level title scene instance exposes a configurable color; white remains the default for existing instances.
- Existing title text, outline, animation timing, visibility, and cleanup remain unchanged.