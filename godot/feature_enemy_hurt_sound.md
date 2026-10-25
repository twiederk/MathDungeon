# Feature: Per-Enemy Hurt Sounds

## Goal

Today `Enemy.hurt()` always plays the single global `Sound.hurt_enemy` stream
(see `enemies/enemy.gd`). Instead, every enemy should be able to define its own
set of hurt sounds in its `EnemyStats` resource, and a random one is picked on
each hit.

## Decisions

| Topic | Decision |
|---|---|
| Fallback | `get_hurt_sound()` accessor on `EnemyStats`, empty-array fallback to `Sound.hurt_enemy` |
| Variants per enemy | All available Minecraft variants (2-4) |
| Projectiles | `arrow`, `fireball`, `blaze_fireball` keep the default sound (no `hurt_sounds`) |
| Licensing | Original Minecraft assets are acceptable (private project) |
| File format | `.ogg` (Vorbis) |

## Design Notes / Constraints

- `@export var hurt_sounds: Array[AudioStream] = [Sound.hurt_enemy]` is **not
  safe**: the initializer runs whenever the resource is instantiated, including
  in the editor where autoloads are not instantiated, and potentially before the
  `Sound` autoload has populated its own `@export` streams. In both cases the
  default resolves to `null` and can be baked into the saved `.tres`.
- Chosen solution: export an empty array and resolve the fallback at play time
  via a getter on `EnemyStats`, consistent with the existing `get_*()` accessor
  style of that class:

  ```gdscript
  @export var hurt_sounds: Array[AudioStream] = []

  func get_hurt_sound() -> AudioStream:
      if hurt_sounds.is_empty():
          return Sound.hurt_enemy
      return hurt_sounds.pick_random()
  ```

  `enemy.gd` then calls `Sound.play(stats.get_hurt_sound())`.
  This keeps all 26 existing `*_stats.tres` files working unchanged.
- Audio files are `.ogg` (Vorbis), matching the project's existing SFX. Avoid
  `.mp3` for these clips - encoder delay/padding adds audible lag to sub-second
  hit sounds.
- Suggested asset location: `enemies/sounds/<enemy>_hurt_<n>.ogg`.

## Phase 1 — Data Model

1. Add `@export var hurt_sounds: Array[AudioStream] = []` to
   `enemies/enemy_stats.gd` (next to `loot_drops`, outside the `Hard` group).
2. Add `func get_hurt_sound() -> AudioStream` with the empty-array fallback to
   `Sound.hurt_enemy`.
3. Unit tests in `test/test_EnemyStats.gd`:
   - returns `Sound.hurt_enemy` when `hurt_sounds` is empty
   - returns the single entry when exactly one sound is configured
   - returns an entry contained in `hurt_sounds` when several are configured

## Phase 2 — Wire Up `Enemy`

1. Change `enemies/enemy.gd` from `Sound.play(Sound.hurt_enemy)` to
   `Sound.play(stats.get_hurt_sound())`.
2. Verify nothing else references `Sound.hurt_enemy` directly.
3. Run the test suite: `cmd /c "test_ING.bat < nul"`.

## Phase 3 — Asset Acquisition

1. Download **all** hurt sound variants (typically 2-4 per mob) for the enemies
   listed in the table below.
2. Convert / trim to short `.ogg` clips (target < 1 s, mono, ~44.1 kHz).
3. Place them under `enemies/sounds/` as `<enemy>_hurt_<n>.ogg`.
4. Run the headless import once so `.import` files are generated:
   `Godot_v4.7-stable_win64.exe --path . --headless --import`

## Phase 4 — Assign Sounds to Stats Resources

1. For each `enemies/*_stats.tres`, add the downloaded streams to
   `hurt_sounds`.
2. Leave `hurt_sounds` empty for projectile stats (`arrow_stats.tres`,
   `fireball_stats.tres`, `blaze_fireball_stats.tres`) so they keep the default.
3. Manual play test: hit each enemy type and confirm the sound varies.

## Phase 5 — Polish (optional)

1. Consider a small random `pitch_scale` jitter in `Sound.play()` for extra
   variety (the parameter already exists).
2. Consider a matching `death_sounds` array if the hurt-sound work lands well.

## Enemy Table

All enemies are Minecraft-style mobs. The Minecraft Wiki hosts the original
`hurt` sound files on each mob's page under the "Sounds" section (click the
download arrow on the audio player).

| # | Stats resource | Enemy | Sound source |
|---|---|---|---|
| 1 | `zombie_stats.tres` | Zombie | https://minecraft.wiki/w/Zombie#Sounds |
| 2 | `zombie_baby_stats.tres` | Baby Zombie | https://minecraft.wiki/w/Zombie#Sounds |
| 3 | `villager_zombie_stats.tres` | Zombie Villager | https://minecraft.wiki/w/Zombie_Villager#Sounds |
| 4 | `villager_zombie_baby_stats.tres` | Baby Zombie Villager | https://minecraft.wiki/w/Zombie_Villager#Sounds |
| 5 | `villager_stats.tres` | Villager | https://minecraft.wiki/w/Villager#Sounds |
| 6 | `villager_baby_stats.tres` | Baby Villager | https://minecraft.wiki/w/Villager#Sounds |
| 7 | `skeleton_stats.tres` | Skeleton | https://minecraft.wiki/w/Skeleton#Sounds |
| 8 | `spider_stats.tres` | Spider | https://minecraft.wiki/w/Spider#Sounds |
| 9 | `creeper_stats.tres` | Creeper | https://minecraft.wiki/w/Creeper#Sounds |
| 10 | `drown_stats.tres` | Drowned | https://minecraft.wiki/w/Drowned#Sounds |
| 11 | `enderman_stats.tres` | Enderman | https://minecraft.wiki/w/Enderman#Sounds |
| 12 | `enderdragon_stats.tres` | Ender Dragon | https://minecraft.wiki/w/Ender_Dragon#Sounds |
| 13 | `blaze_stats.tres` | Blaze | https://minecraft.wiki/w/Blaze#Sounds |
| 14 | `ghast_stats.tres` | Ghast | https://minecraft.wiki/w/Ghast#Sounds |
| 15 | `piglin_stats.tres` | Piglin | https://minecraft.wiki/w/Piglin#Sounds |
| 16 | `piglin_boss_stats.tres` | Piglin Brute | https://minecraft.wiki/w/Piglin_Brute#Sounds |
| 17 | `piglin_zombie_stats.tres` | Zombified Piglin | https://minecraft.wiki/w/Zombified_Piglin#Sounds |
| 18 | `pig_stats.tres` | Pig | https://minecraft.wiki/w/Pig#Sounds |
| 19 | `iron_golem_stats.tres` | Iron Golem | https://minecraft.wiki/w/Iron_Golem#Sounds |
| 20 | `evoker_stats.tres` | Evoker | https://minecraft.wiki/w/Evoker#Sounds |
| 21 | `evoker_vex_stats.tres` | Vex | https://minecraft.wiki/w/Vex#Sounds |
| 22 | `vindicator_stats.tres` | Vindicator | https://minecraft.wiki/w/Vindicator#Sounds |
| 23 | `pillager_stats.tres` | Pillager | https://minecraft.wiki/w/Pillager#Sounds |
| 24 | `arrow_stats.tres` | Arrow (projectile) | no hurt sound — keep default |
| 25 | `fireball_stats.tres` | Fireball (projectile) | no hurt sound — keep default |
| 26 | `blaze_fireball_stats.tres` | Blaze Fireball (projectile) | no hurt sound — keep default |

### Alternative / royalty-free sources

| Source | URL | Note |
|---|---|---|
| The Sounds Resource | https://www.sounds-resource.com/pc_computer/minecraft/ | Bulk rips of the original files |
| Freesound | https://freesound.org/ | CC0/CC-BY, good for custom replacements |
| OpenGameArt | https://opengameart.org/art-search?keys=monster+hurt | CC0 monster SFX packs |
| Kenney SFX | https://kenney.nl/assets/impact-sounds | CC0 impact/hit sounds |

> Licensing note: Minecraft's original sound assets are proprietary. Acceptable
> for this private project. If MathDungeon is ever distributed publicly, replace
> them with CC0 assets from the alternative sources above.
