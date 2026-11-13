# RPG Enemy Idle Animation

## Goal

Animate the stationary RPG Skeleton, Skeleton Swordless, and Slime using frames 0, 1, and 2 of their idle row. Play the animation automatically and loop it while the game is running. Preserve sprite flipping for surprise-attack direction; no movement or directional animation is needed.

## Current State

- The three scenes in `procedural/enemies/` use a static `Sprite2D` named `Sprite2D`, positioned at `(0, -8)`.
- The skeleton sheets are 288 x 624 pixels, with a 6 x 13 grid of 48 x 48 cells. The slime sheet is 224 x 416 pixels, with 32 x 32 cells in a 7 x 13 grid; its current scene specifies `hframes = 6`, which does not divide the sheet width evenly.
- `enemies/enemy.gd` expects `$Sprite2D` to be a `Sprite2D` and sets its `flip_h` in `_ready()`. The same script also implements classic enemy orientation and surprise-attack logic.
- `procedural/enemy_generator.gd` instantiates these scenes as `Enemy` nodes and does not change their orientation.

## Phase 1: Shared Enemy Compatibility

1. Keep the existing `Sprite2D` child name so the shared node path and scene structure remain compatible. Allow the sprite reference in `enemies/enemy.gd` to refer to either a static `Sprite2D` or an `AnimatedSprite2D`.
2. Apply the existing `flip_sprite` visual setting to both `Sprite2D` and `AnimatedSprite2D` nodes, so the visual orientation matches the surprise-attack direction. Preserve the existing `_attack_type_for` and `_is_behind` behavior and all classic enemy behavior.
3. Keep enemy stats, detection, collision shapes, signals, and damage handling unchanged.

## Phase 2: Idle Animations

1. Replace the static sprite in each of `skeleton.tscn`, `skeleton_swordless.tscn`, and `slime.tscn` with an `AnimatedSprite2D` named `Sprite2D`, retaining its position and visual alignment.
2. Follow the existing `enemies/hit_effect.tscn` pattern: use scene-local `SpriteFrames` and `AtlasTexture` subresources referencing each enemy's own sheet. A separate shared resource is unnecessary because the three textures differ.
3. Define a looping `idle` animation using the first three cells in the top row, in order. For both skeleton sheets use regions `(0, 0, 48, 48)`, `(48, 0, 48, 48)`, and `(96, 0, 48, 48)`. For the slime use `(0, 0, 32, 32)`, `(32, 0, 32, 32)`, and `(64, 0, 32, 32)`; verify the corrected cell size against the artwork and collision alignment.
4. Configure `idle` to autoplay at an initial 5 frames per second, matching the existing hit-effect resource's playback rate. Tune the rate only if visual inspection shows it is unsuitable. Preserve the pixel-art filtering and centered sprite behavior.

## Phase 3: Verification

1. Add focused GUT coverage that instantiates all three scenes in the tree and checks the `idle` animation, its three frame textures and atlas regions, looping, autoplay, and actual frame advancement over time.
2. Verify enemy detection and damage still work, and that both classic static and RPG animated enemies honor `flip_sprite` in both orientations. Check that surprise attacks use the corresponding direction and that pausing and resuming simulation stops and restarts the animations with the existing enemy process-mode handling.
3. Run the focused enemy and procedural-generation tests, then the full GUT suite using `test_ING.bat`.
4. Play a procedural world and visually check all three enemies for correct idle frames, scale and alignment, smooth looping, and no movement. Check both sprite orientations and the slime especially because its existing grid setting differs from the sheet dimensions.