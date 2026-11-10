# Feature: RPGPlayer

## Goal

Give `ProcGenWorld` a dedicated player scene with its own texture and collision geometry,
while reusing the existing movement, sprinting, potion, and camera behavior. Prepare the
design for a sprite sheet, `AnimatedSprite2D`, `AnimationPlayer`, and `AnimationTree`.

## Decisions

- Name the procedural variant `RPGPlayer`.
- Use independent classic and RPG player scenes, not Editable Children overrides inside
  `ProcGenWorld` and not scene inheritance. The variants will eventually have different
  visual node structures.
- Use script inheritance to share behavior: `ClassicPlayer extends Player` and
  `RPGPlayer extends Player`.
- Keep `Player` in `classic/player.gd` initially to avoid unrelated file moves.
- Keep the world-facing interface compatible: `Player` type, `apply_portrait()`,
  `set_camera_limits()`, and the world child named `Player`.
- Shared code must not require `Sprite2D`, `AnimatedSprite2D`, `AnimationPlayer`, or
  `AnimationTree`. Each variant owns its visual nodes and visual behavior.
- Classic players continue displaying the selected character portrait. RPG players use
  their own artwork; applying a character portrait must not replace it.
- Collision dimensions belong to each scene. Use a separate `Shape2D` resource for the
  RPG player, not a shared shape and not root scaling to adjust collision size.
- Implement in independently usable phases. Animation nodes are not required for the
  initial RPG player.

## Current Constraints

- `classic/player.gd` directly binds `$Sprite2D` as `Sprite2D`, changes its texture in
  `apply_portrait()`, and flips it in `_update_sprite_direction()`.
- `WorldLevel._setup_player_portrait()` calls `player.apply_portrait()` at startup. A
  scene-only texture override would therefore be overwritten.
- `WorldLevel` and `CompanionSetup` expect a `Player`. Both variants must remain subclasses
  of that type.
- `ProcGenWorld` currently instances `classic/player.tscn`.

## Phase 1 - Separate Shared Behavior from Classic Visuals

1. Keep input, velocity calculation, `move_and_slide()`, potion usage, speed constants,
   and camera limits in `Player`.
2. Introduce a visual-update hook accepting the full movement input direction and the
   actual velocity after `move_and_slide()`. Call it from the shared physics loop.
   Passing both supports facing into a wall without playing a walking animation while
   blocked, and allows four-direction animation later.
3. Give the base hook and `apply_portrait()` default no-op implementations. The base
   class must not access any sprite node.
4. Add `classic/classic_player.gd` with `class_name ClassicPlayer`, extending `Player`.
   Move the `Sprite2D` binding, portrait assignment, and horizontal facing logic into it.
5. Attach `ClassicPlayer` to `classic/player.tscn`. Keep its existing nodes, texture,
   collider, camera, and root name unchanged.
6. Leave `WorldLevel` and companion APIs unchanged. Do not introduce checks for concrete
   player variants in world code.

### Validation

- Reuse existing player tests where available; add focused cases for classic portrait
  assignment and facing, including retaining the previous facing on zero horizontal input.
- Verify a base `Player` with a camera but no visual nodes does not require `Sprite2D`.
- Verify classic movement, sprinting, potion use, and camera limits still work.
- Import new script classes before running the focused GUT tests.

**Done when:** classic gameplay is unchanged and shared behavior no longer depends on a
specific sprite node type.

## Phase 2 - Add the Static RPGPlayer

1. Add `procedural/rpg_player.gd` with `class_name RPGPlayer`, extending `Player`.
2. Add an independent `procedural/rpg_player.tscn`:

   ```text
   RPGPlayer (CharacterBody2D, RPGPlayer script)
   |-- Sprite2D
   |-- CollisionShape2D
   `-- Camera2D
   ```

3. Assign the RPG texture and a dedicated collision shape. Choose dimensions and offsets
   against the actual artwork and 16-pixel world tiles. For a top-down character, place
   the collider around the feet rather than the entire visible body where appropriate.
4. Preserve the existing player's collision layers, masks, and relevant body settings.
   Keep speed unchanged unless a separate gameplay requirement calls for tuning it.
5. Implement static facing in `RPGPlayer` using the visual hook. Inherit the no-op
   `apply_portrait()` so the RPG texture survives world initialization.
6. Replace only the player scene reference in `procedural/proc_gen_world.tscn`.
   Keep the instance named `Player` and preserve its world position.
7. Leave all classic worlds using `classic/player.tscn`.

### Validation

- Instantiate both scenes and verify both roots are `Player` instances.
- Verify applying a portrait changes the classic sprite but leaves the RPG sprite unchanged.
- Verify the collider resources are independent and changing one cannot change the other.
- Smoke-test `ProcGenWorld`: wall collisions, narrow passages, camera limits, potion use,
  companions, encounters, pause, and resume.
- Check a classic world still uses its original player appearance and collision geometry.

**Done when:** `ProcGenWorld` uses its own player artwork and collider without duplicating
movement code or changing classic gameplay.

## Phase 3 - Introduce the Sprite Sheet and AnimatedSprite2D

1. Replace only the RPG scene's `Sprite2D` with `AnimatedSprite2D`; update its script binding.
2. Create a `SpriteFrames` resource containing frames from the chosen sprite-sheet texture.
   `SpriteFrames` is the resource consumed by `AnimatedSprite2D`, not the texture alone.
3. Define idle and walk animations for the directions supported by the artwork. Use a
   consistent naming scheme such as `idle_down`, `walk_down`, and corresponding directions.
4. Store the last nonzero facing direction, initialized to down. Use actual movement to
   select idle versus walk and input direction to update facing. Define a deterministic
   diagonal policy, for example choosing vertical facing when both input components tie.
5. For this phase, let `RPGPlayer` select and play `AnimatedSprite2D` animations directly.
   Do not restart an unchanged animation every physics frame.
6. Preserve the collider and camera. Align the new frames with the established feet origin.
   Add distinct sprint artwork only if available; otherwise reuse walking visuals.

### Validation

- Test initial facing, each supported direction, diagonal selection, idle facing retention,
  and idle while pushing against a wall.
- Check transitions between idle, walking, and sprinting without repeated frame resets.
- Inspect sprite-sheet slicing, frame alignment, and collision alignment in the running world.
- Confirm classic rendering still has no dependency on animated sprite resources.

**Done when:** the RPG player uses the sprite sheet with correct movement and idle visuals.

## Phase 4 - Add AnimationPlayer and AnimationTree

1. Add `AnimationPlayer` and `AnimationTree` as RPG-only children:

   ```text
   RPGPlayer (CharacterBody2D, RPGPlayer script)
   |-- AnimatedSprite2D
   |-- CollisionShape2D
   |-- Camera2D
   |-- AnimationPlayer
   `-- AnimationTree
   ```

2. Configure `AnimationPlayer` clips to animate `AnimatedSprite2D.animation` and `frame`,
   reusing the `SpriteFrames` resource. Include deliberate reset values for animated
   properties and use discrete property tracks for animation names and frame indices.
3. Build an `AnimationTree` state machine with Idle and Walk states. For four-direction
   artwork, use discrete directional blend spaces inside those states. Add a Run state
   only when distinct sprint animations exist.
4. Make `AnimationTree` the only playback controller, driving the `AnimationPlayer` clips.
   Disable `AnimatedSprite2D` autoplay and remove the phase 3 `play()` calls. Do not call
   `AnimationPlayer.play()` alongside an active tree.
5. Have the RPG visual hook update facing parameters and request state transitions.
   Keep movement decisions in `Player`; animations must not move the physics body.
6. Configure animation processing consistently with physics updates. Preserve animation
   timing across unchanged states rather than restarting playback every update.
7. Keep all animation nodes under the player so the existing simulation pause behavior
   disables them together. Verify pause and resume retain a coherent visual state.

### Validation

- Verify the tree references the correct `AnimationPlayer`, every animation track resolves,
  and all states and directional parameters exist.
- Test state selection and facing parameters through the RPG visual hook.
- Manually check movement, stopping, wall blocking, direction changes, sprinting, pause,
  and resume. Confirm there are no competing playback controllers or animation errors.
- Rerun shared and classic player regression tests.

**Done when:** `AnimationTree` controls RPG animation playback without changing shared
movement behavior or classic visuals.

## Test and Integration Guidelines

- Extend nearby GUT tests and helpers where suitable. Add a dedicated RPG player test
  file only when the variant-specific cases need their own home.
- Follow the repository's arrange/act/assert convention, with one statement in each act block.
- Run a headless Godot import after introducing script classes or scene resources, then
  run focused tests for the changed phase. Run the full suite at integration milestones.
- Use deterministic inputs and movement values for visual-selection tests; do not make
  unit tests depend on exact real-time animation playback positions.
- Artwork selection, exact collider dimensions, and available animation directions must
  be confirmed against the supplied assets during the relevant phase.

## Out of Scope

- Changing player statistics, inventory, saves, input mappings, or movement balance.
- Converting classic players to animated sprites.
- Adding combat, interaction, or damage animation states before those behaviors require them.
- Reorganizing shared scripts into a new directory or introducing a general animation framework.