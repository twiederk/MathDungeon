# Minecraft Enemy Item Drops

Reference for the enemy types represented in this project. Drops below summarize **Minecraft Java Edition 26.3**, using default drops without Looting unless a condition is stated. Quantities and chances refer to item drops, not experience orbs. The Minecraft Wiki pages linked in the table include edition-specific and additional conditions.

| Stats resource | Name in stats | Minecraft mob | Item drops in Minecraft |
|---|---|---|---|
| `blaze_stats.tres` | Blaze | [Blaze](https://minecraft.wiki/w/Blaze) | Blaze Rod: 0–1, 50%; requires a player or tamed-wolf kill. |
| `creeper_stats.tres` | Creeper | [Creeper](https://minecraft.wiki/w/Creeper) | Gunpowder: 0–2, 66.7%. A random music disc drops if killed by a skeleton-family mob; a Creeper Head drops if killed by a charged creeper. |
| `drown_stats.tres` | Drowned | [Drowned](https://minecraft.wiki/w/Drowned) | Rotten Flesh: 0–2, 66.7%. Copper Ingot: 0–1, 11%, on player/tamed-wolf kill. A spawned Nautilus Shell carrier always drops its shell (3% spawn chance in Java). A held Trident or Fishing Rod has an 8.5% drop chance on player/tamed-wolf kill. |
| `enderdragon_stats.tres` | Ender Dragon | [Ender Dragon](https://minecraft.wiki/w/Ender_Dragon) | Dragon Egg appears on the first defeat only in Java Edition. Later defeats do not drop another egg. The exit portal and End gateway are generated as fight rewards, not inventory items. |
| `enderman_stats.tres` | Enderman | [Enderman](https://minecraft.wiki/w/Enderman) | Ender Pearl: 0–1, 50%. An Enderman also drops the block it is carrying, if any. It does **not** drop an Eye of Ender in Minecraft. |
| `evoker_vex_stats.tres` | Vex | [Vex](https://minecraft.wiki/w/Vex) | No item drops. Its held Iron Sword is configured not to drop. |
| `evoker_stats.tres` | Evoker | [Evoker](https://minecraft.wiki/w/Evoker) | Totem of Undying: 1, guaranteed. Emerald: 0–1, 50%, on player/tamed-wolf kill. Raid-captain drops are conditional. |
| `ghast_stats.tres` | Ghast | [Ghast](https://minecraft.wiki/w/Ghast) | Ghast Tear: 0–1, 50%. Gunpowder: 0–2, 66.7%. Music Disc Tears drops if killed by a player-deflected fireball. |
| `iron_golem_stats.tres` | Iron Golem | [Iron Golem](https://minecraft.wiki/w/Iron_Golem) | Iron Ingot: 3–5, guaranteed. Poppy: 0–2, 66.7%. |
| `pig_stats.tres` | Pig | [Pig](https://minecraft.wiki/w/Pig) | Adult: Raw Porkchop, 1–3, guaranteed; Cooked Porkchop instead if killed while burning. A saddled Pig drops its Saddle. Baby Pigs drop no items. |
| `piglin_boss_stats.tres` | Piglin Brute | [Piglin Brute](https://minecraft.wiki/w/Piglin_Brute) | Golden Axe: 8.5% on player/tamed-wolf kill; Looting adds 1 percentage point per level. |
| `piglin_stats.tres` | Piglin | [Piglin](https://minecraft.wiki/w/Piglin) | No ordinary item drops. Each naturally held/worn equipment item has an 8.5% drop chance on player/tamed-wolf kill. A Gold Ingot drops if the Piglin is killed in one hit while admiring it; a Piglin Head drops if killed by a charged creeper. |
| `piglin_zombie_stats.tres` | Zombified Piglin | [Zombified Piglin](https://minecraft.wiki/w/Zombified_Piglin) | Rotten Flesh: 0–1, 50%. Gold Nugget: 0–1, 50%. Gold Ingot: 0–1, 2.5%, on player/tamed-wolf kill. Naturally held equipment can also drop. |
| `pillager_stats.tres` | Pilligar | [Pillager](https://minecraft.wiki/w/Pillager) | Crossbow: 8.5% on player/tamed-wolf kill. A raid captain drops its Ominous Banner; outside a raid, a captain also drops an Ominous Bottle. |
| `skeleton_stats.tres` | Skeleton | [Skeleton](https://minecraft.wiki/w/Skeleton) | Bone: 0–2, 66.7%. Arrow: 0–2, 66.7%. Bow: 8.5% on player/tamed-wolf kill. Skeleton Skull drops if killed by a charged creeper. |
| `spider_stats.tres` | Spider | [Spider](https://minecraft.wiki/w/Spider) | String: 0–2, 66.7%. Spider Eye: 0–1, 33.3%, on player/tamed-wolf kill. |
| `villager_baby_stats.tres` | Baby Villager | [Baby Villager](https://minecraft.wiki/w/Villager) | No item drops when killed. |
| `villager_stats.tres` | Villager | [Villager](https://minecraft.wiki/w/Villager) | Normally no item drops when killed. A Farmer that used Bone Meal while farming has an 8.5% chance to drop it on player/tamed-wolf kill. Armor equipped by a dispenser can drop. |
| `villager_zombie_baby_stats.tres` | Baby Zombie Villager | [Baby Zombie Villager](https://minecraft.wiki/w/Zombie_Villager) | Same item drops as a Zombie Villager. Baby variants give more experience, not a different ordinary item-drop table. |
| `villager_zombie_stats.tres` | Zombie Villager | [Zombie Villager](https://minecraft.wiki/w/Zombie_Villager) | Rotten Flesh: 0–2, 66.7%. Iron Ingot, Carrot, and Potato: each 0–1, 0.83%, on player/tamed-wolf kill; a Potato becomes baked if the mob is burning or killed with Fire Aspect. Naturally spawned equipment has an 8.5% drop chance on player/tamed-wolf kill. |
| `vindicator_stats.tres` | Vindicator | [Vindicator](https://minecraft.wiki/w/Vindicator) | Emerald: 0–1, 50%, on player/tamed-wolf kill. Iron Axe: 8.5% on player/tamed-wolf kill; Looting adds 1 percentage point per level. Raid-captain drops are conditional. |
| `zombie_baby_stats.tres` | Baby Zombie | [Baby Zombie](https://minecraft.wiki/w/Zombie) | Same ordinary item drops as a Zombie: Rotten Flesh and rare Iron Ingot, Carrot, or Potato. The baby variant differs in experience, not ordinary item drops. |
| `zombie_stats.tres` | Zombie | [Zombie](https://minecraft.wiki/w/Zombie) | Rotten Flesh: 0–2, 66.7%. Iron Ingot, Carrot, and Potato: each 0–1, 0.83%, on player/tamed-wolf kill; a Potato becomes baked if the mob is burning or killed with Fire Aspect. Zombie Head drops if killed by a charged creeper. |

## Project Mapping Notes

- `pillager_stats.tres` is still named `Pilligar` and is used by `shooting_pillager.tscn`. The Evoker uses its own `evoker_stats.tres` resource.
- `zombie_baby_stats.tres` is named `Baby Zombie` and is used by `zombie_baby.tscn`.
- `arrow_stats.tres`, `blaze_fireball_stats.tres`, and `fireball_stats.tres` describe projectiles, not enemy types, so they are not listed as enemy rows. Shooting variants reuse their base enemy stats and are covered by the corresponding row.

The Minecraft Wiki is community-maintained and is not affiliated with Mojang or Microsoft. Links point to the individual mob pages; the table is a concise summary of their drop information.
