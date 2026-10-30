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
5. **`enemies/*_stats.tres`** (all non-projectile enemy stats resources)
   - Add `death_sounds = Array[AudioStream]([])` (empty array) next to each
     resource's `hurt_sounds` line, ready for the user to fill in via the editor.

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

## Out of Scope
- Projectiles (`Projectile`/`shooting_enemy.gd`) — no hurt/death sound change needed;
  already unaffected since the transient `Enemy` instance they create is never added
  to the tree.
- Actually sourcing/assigning the death sound audio files — only the code structure
  and empty placeholders are covered here.
