# Feature: Death Sound

## Goal
When an enemy is defeated (hit points reach 0), play a randomly picked death sound
instead of the hurt sound. Non-lethal hits keep playing the hurt sound as before.
Projectiles (transient `Enemy` instances created by `Projectile`, never added to the
tree) are unaffected — they already don't play any sound since `hurt()` only plays
sounds when `is_inside_tree()` is true.

## Scope / Decisions
- Add `death_sounds: Array[AudioStream]` to `EnemyStats`, mirroring `hurt_sounds`.
- Add `get_death_sound() -> AudioStream` to `EnemyStats`, mirroring `get_hurt_sound()`,
  falling back to a new `Sound.death_enemy` default when `death_sounds` is empty.
- Add `death_enemy: AudioStream` export to the `Sound` autoload (`classic/sound.gd`,
  `classic/sound.tscn`), as the fallback default death sound (asset assigned later
  in the editor).
- `Enemy.hurt()`: when the hit is lethal (`hit_points <= 0` after damage), play
  `stats.get_death_sound()` instead of `stats.get_hurt_sound()`. Non-lethal hits keep
  playing the hurt sound. The hit effect (`_spawn_hit_effect()`) still spawns in both
  cases (no change there).
- Populate `death_sounds` in all existing `*_stats.tres` resources the same way
  `hurt_sounds` is populated today, except for projectile stats (`arrow_stats`,
  `fireball_stats`, `blaze_fireball_stats`), which are excluded — same list used by
  `test_all_non_projectile_stats_define_hurt_sounds`. Since no death sound assets
  exist yet, these entries will be left as empty arrays for now (follow-up task to
  assign actual audio files), matching how the user will populate them manually in
  the editor.
- **Folder layout change**: hurt sound files currently live flat in
  `enemies/sounds/` (e.g. `enemies/sounds/Zombie_hurt1.ogg`, referenced as
  `ExtResource`s in each `*_stats.tres`). Going forward:
  - All hurt sound files move to `enemies/hurt_sounds/`.
  - All death sound files are stored in `enemies/death_sounds/`.

## Implementation Steps

1. **`classic/sound.gd`**
   - Add `@export var death_enemy: AudioStream` next to `hurt_enemy`.
2. **`classic/sound.tscn`**
   - Leave `death_enemy` unassigned (empty) for the user to assign an audio file
     later, same pattern as adding any other `Sound` export — no `ext_resource`
     needed until an asset is chosen.
3. **`enemies/enemy_stats.gd`**
   - Add `@export var death_sounds: Array[AudioStream] = []` next to `hurt_sounds`.
   - Add:
     ```gdscript
     func get_death_sound() -> AudioStream:
         if death_sounds.is_empty():
             return Sound.death_enemy
         return death_sounds.pick_random()
     ```
4. **`enemies/enemy.gd`**
   - Update `hurt()` so it only plays the hurt sound for non-lethal hits, and plays
     the death sound once the enemy is defeated:
     ```gdscript
     func hurt(damage: int) -> int:
         hit_points -= max(1, damage - stats.get_armor())
         if is_inside_tree():
             if hit_points <= 0:
                 Sound.play(stats.get_death_sound())
             else:
                 Sound.play(stats.get_hurt_sound())
             _spawn_hit_effect()
         if hit_points <= 0:
             defeated.emit(self)
         return hit_points
     ```
     (Damage is applied before the sound check so the lethal/non-lethal branch can
     be determined; behavior for `defeated.emit()` timing is unchanged.)
5. **Move existing hurt sound files**: `enemies/sounds/*.ogg` → `enemies/hurt_sounds/*.ogg`
   (keep the same file names). Update every `*_stats.tres` `ext_resource` `path=`
   entry pointing at `res://enemies/sounds/...` to `res://enemies/hurt_sounds/...`.
   Godot/`uid://` references should still resolve by UID after the move, but paths
   in the `.tres` text need updating to match (and re-importing if `.import` files
   don't follow the move automatically — verify with `--headless --import`).
   - Delete the now-empty `enemies/sounds/` folder once confirmed empty.
6. **Create `enemies/death_sounds/`** folder for the new death sound audio files
   sourced in the section below.
7. **`enemies/*_stats.tres`** (all non-projectile enemy stats resources)
   - Add `death_sounds = Array[AudioStream]([])` (empty array) next to each
     resource's `hurt_sounds` line, ready for the user to fill in via the editor
     once files exist under `enemies/death_sounds/`.

## Tests (`test/test_EnemyStats.gd`)
- `test_get_death_sound_falls_back_to_default_when_empty`: new `EnemyStats`,
  assert `get_death_sound() == Sound.death_enemy`.
- `test_get_death_sound_returns_single_configured_sound`: set `death_sounds` to one
  stream, assert it's returned.
- `test_get_death_sound_returns_one_of_the_configured_sounds`: set `death_sounds`
  to several streams, assert the result is one of them (`assert_has`).
- `test_all_non_projectile_stats_define_death_sounds`: mirror
  `test_all_non_projectile_stats_define_hurt_sounds`, iterating `*_stats.tres`
  files (excluding `arrow_stats`, `fireball_stats`, `blaze_fireball_stats`) and
  asserting none have an empty `death_sounds` array. (This test will initially fail
  until the `.tres` files are populated with real audio assets — expected to pass
  once step 5's placeholders are replaced with actual sounds.)

## Tests (`test/test_Enemy.gd`)
- `test_lethal_damage_plays_death_sound_not_hurt_sound`: enemy at full health,
  `watch_signals`/mock not available for `Sound.play` directly — instead verify via
  existing pattern (check `defeated` still emits) and, if feasible, spy on
  `Sound.play` calls (may need a lightweight test double or to assert indirectly
  through stats' `get_death_sound`/`get_hurt_sound` call counts if GUT stubbing is
  available in this codebase — confirm existing test utilities support stubbing
  autoload methods before writing this test).
- `test_nonlethal_damage_still_plays_hurt_sound`: similar indirect verification for
  the non-lethal branch, ensuring no regression.

## Sourcing Death Sound Assets from the Local Minecraft Installation
Minecraft is installed on this machine, so the real per-mob death sounds can be
extracted from it instead of using placeholders, the same way the existing
`enemies/sounds/*_hurt*.ogg` assets were presumably sourced (those files are being
moved to `enemies/hurt_sounds/` as part of this feature, see step 5 above):

1. Locate the client jar for an installed version, e.g.
   `%APPDATA%\.minecraft\versions\<version>\<version>.jar`.
2. Extract `assets/minecraft/sounds/entity/<mob>/death*.ogg` (and `hurt*.ogg` for
   reference/consistency) from the jar — e.g. via `Expand-Archive` after renaming
   the `.jar` to `.zip`, or any zip tool.
3. Match extracted mob sound folders to this project's enemies (e.g.
   `entity/zombie/death1.ogg` → `zombie_stats.tres`, `entity/skeleton/death1.ogg` →
   `skeleton_stats.tres`, `entity/enderman/death.ogg` → `enderman_stats.tres`, etc.).
   Some project enemies don't map 1:1 to vanilla mobs (e.g. `chasing_iron_golem`,
   `evoker_vex`) — use the closest matching vanilla entity folder.
4. Copy the chosen `.ogg` files into `enemies/death_sounds/`, following the existing
   naming convention used in `enemies/hurt_sounds/`
   (e.g. `Zombie_hurt1.ogg` → `Zombie_death1.ogg`), referenced as `ExtResource`s
   in the `*_stats.tres` files.
5. Let Godot import them (`.import` files are generated automatically), then wire
   each enemy's `death_sounds` array in its `.tres` to the imported `AudioStream`
   resources under `res://enemies/death_sounds/...`, replacing the empty
   placeholders from step 7 above.
6. Pick/record one general-purpose fallback sound for `Sound.death_enemy` (e.g. a
   generic vanilla "entity.generic.death" sound) and assign it in `sound.tscn`.

This step replaces the "empty array placeholder" fallback mentioned above with
actual audio once the assets are extracted and imported — it should be done before
the `test_all_non_projectile_stats_define_death_sounds` test is expected to pass.

## Out of Scope
- Projectiles (`Projectile`/`shooting_enemy.gd`) — no hurt/death sound change needed;
  already unaffected since the transient `Enemy` instance they create is never added
  to the tree.
- Writing a script to automate the jar extraction/mapping — done manually per the
  steps above unless you ask for an extraction script.
