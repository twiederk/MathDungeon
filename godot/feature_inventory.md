# Feature: Inventory System

## Goal

Give the player a persistent, visible inventory that actually changes gameplay decisions, not just an
automatic stat upgrade on pickup. Target audience is young kids practicing basic math, so the UI and
rules must stay simple: few slots, clear icons, one obvious action per item.

## Decisions (confirmed)

1. Equipment uses **fixed slots** (one Weapon slot, one Armor slot). No free-form bag for gear.
2. Items can be picked up both from **rooms** (placed `Item` nodes) and as **enemy drops** (existing
   `LootDropper` / `LootDropDefinition`).
3. The inventory must **affect gameplay**, not just be a display: consumables are stored and used on
   demand instead of being auto-consumed on pickup, so the player must decide *when* to drink a potion.

## Current state (for reference)

- `Item` (`items/item.gd`) is an `Area2D`; touching the player emits `item_picked_up`, and
  `WorldLevel._on_item_picked_up()` immediately calls `item.execute()` and frees the node. There is no
  storage step at all today.
- `Sword` / `Helmet` write directly into `CharacterManager.current.weapon_damage` / `.armor`, only if the
  new value is better than the current one. The "old" item is simply discarded.
- `HealingPotion` heals instantly on pickup (wasted if full HP, no choice to save it).
- `Lighter` and `EyeOfEnder` are quest/key items tracked as flags/counters directly on `GameSession`
  (`has_lighter`, `eyes_of_ender`). They are not meant to be managed by the player, so they stay as-is.
- `StatsSheet` (`gui/stats_sheet.gd`) already shows HP, damage and armor numbers. It is reused both as
  the always-on player HUD (`PlayerStatsSheet` in each level scene) and as the enemy panel inside the
  quiz dialog (`EnemyStatsSheet`), so it must stay generic and gets embedded, not rebuilt, by the new
  character sheet screen.
- `Character` (`characters/character.gd`) holds `weapon_damage`, `armor`, `hit_points` and is saved via
  `SaveManager.save_character()`.

## Scope

### In scope
- Weapon slot, Armor slot (both fixed, exactly one item each).
- A small fixed number of Consumable slots (start with 1 type: Healing Potion, stacked as a count).
- Manual "use" action for consumables (keybind + inventory UI button).
- Equip/replace flow for Weapon and Armor, using the existing "only replace if better" rule to keep
  decisions simple for kids (no drag-and-drop, no selling/discarding UI).
- A dedicated **Character Sheet screen**, toggled like the existing Quest Log (own `DisplayState`, own
  input action, pauses the simulation while open), showing stats + equipped gear + consumables.
- Save/load of **weapon and armor only** via `SaveManager`.

### Out of scope (future work, not part of this feature)
- Trading, dropping items back into the world, or multiple weapon/armor loadouts.
- Key items (Lighter, Eye of Ender) moving into the slot system — they remain `GameSession` flags, but
  get a read-only row in the character sheet for visibility/motivation.
- Stat bonuses beyond damage/armor/healing (e.g. speed items) — can reuse the same slot pattern later.
- Persisting potions / lighter / eyes of ender across saves — these reset each session (see Persistence).
- Changes to `gui/pause_menu.tscn` — it stays exactly as-is; the character sheet is a separate screen.

## Design

### Data model

New class `characters/inventory.gd`:

```gdscript
class_name Inventory

enum SlotType { WEAPON, ARMOR, CONSUMABLE_POTION }

signal changed

var weapon_item_id: String = ""      # e.g. "sword_iron"
var weapon_damage: int = 0
var armor_item_id: String = ""       # e.g. "helmet_iron"
var armor_value: int = 0
var potion_count: int = 0
const MAX_POTIONS: int = 5

func equip_weapon(item_id: String, damage: int) -> bool   # returns true if it replaced the current one
func equip_armor(item_id: String, armor: int) -> bool
func add_potion() -> bool                                  # false if already at MAX_POTIONS
func use_potion() -> bool                                  # false if count == 0
```

`Inventory` is owned by `Character` (one instance per character), mirroring how `weapon_damage` /
`armor` live on `Character` today. `Character.weapon_damage` / `Character.armor` become computed
pass-throughs to `inventory.weapon_damage` / `inventory.armor_value` so existing combat code
(`get_damage()`, `get_armor()`, `hurt()`) keeps working unchanged.

### Item changes

- `Sword.execute()` / `Helmet.execute()` call `CharacterManager.current.inventory.equip_weapon(...)` /
  `equip_armor(...)` instead of writing stats directly. Keep the "only equip if better" rule and the
  pickup sound; still `queue_free()` on pickup (the old gear is not kept as a physical item).
- `HealingPotion.execute()` calls `CharacterManager.current.inventory.add_potion()` instead of healing
  immediately. If the potion slot is full, play a distinct "can't carry more" sound/feedback instead of
  silently doing nothing (important for kids to understand why pickup had no effect).
- New input action `use_potion` (default key, e.g. `H`) and a button on the inventory UI both call
  `CharacterManager.current.inventory.use_potion()`, which heals the player by a fixed amount (or to
  full, matching current potion behavior) when count > 0.
- `Lighter` / `EyeOfEnder` stay unchanged (`GameSession` flags), just get surfaced read-only in the UI.

### UI

Note: `StatsSheet` (`gui/stats_sheet.tscn`) is reused today both as the always-visible player HUD
(`PlayerStatsSheet` in `world_level.gd`) and as the enemy panel inside `quiz_dialog.tscn`
(`EnemyStatsSheet`). It must **not** be restructured — the new screen embeds it rather than replacing it.

- New scene `gui/character_sheet_gui.tscn` / `character_sheet_gui.gd`, built the same way as
  `quests/quest_log_gui.gd`:
  - Listens to `GameSession.display_state_changed`; shows/hides itself and flips `visible`.
  - New input action `character_sheet` toggles `GameSession.display_state` between `NONE` and the new
    `DisplayState.CHARACTER_SHEET` value (mirrors the `quest_log` action/`QUEST_LOG` state pair).
  - Because `is_simulation_running()` already checks `display_state == DisplayState.NONE`, opening the
    character sheet automatically pauses the simulation like the quest log does — no extra wiring needed.
  - Contents: an embedded `StatsSheet` instance (HP/damage/armor, unchanged), plus new rows for Weapon
    icon, Armor icon, Potion count + "Use" button, and read-only Lighter / Eyes of Ender indicators.
- `gui/pause_menu.tscn` / `pause_gui.tscn` are **not modified** — pausing and the character sheet remain
  two separate, independently toggled screens.
- The character sheet listens to `Inventory.changed` (and existing `GameSession` signals) to refresh,
  following the existing signal-driven pattern used by `weapon_damage_changed` / `armor_changed`.

### Persistence

- `SaveManager.save_character()` / the character load path only gain fields for **equipped weapon
  (id + damage) and equipped armor (id + armor value)**, following the existing `load_state(...)`
  parameter style in `character.gd`.
- Potion count, `has_lighter` and `eyes_of_ender` are **not persisted** — they already reset via
  `GameSession.reset()` and the new `Inventory.potion_count` should reset to `0` on a fresh session the
  same way, with no `SaveManager` involvement.

## Implementation phases

### Phase 1 — `Inventory` data class

- Add `characters/inventory.gd` with the `class_name Inventory` shown above (weapon/armor/potion state,
  `equip_weapon()`, `equip_armor()`, `add_potion()`, `use_potion()`, `changed` signal).
- Add `test/test_inventory.gd` (GUT): equipping a lower-damage/armor item is rejected (returns `false`,
  state unchanged), equipping a higher one replaces it and emits `changed`, `add_potion()` is rejected
  once `potion_count == MAX_POTIONS`, `use_potion()` is rejected at `potion_count == 0` and otherwise
  decrements by 1.
- No other file is touched yet — this phase is pure, isolated data/logic that can be fully unit tested
  before anything in the game references it.

### Phase 2 — Wire `Inventory` into `Character`

- In `characters/character.gd`, add `var inventory: Inventory = Inventory.new()`.
- Turn `weapon_damage` and `armor` from stored fields into computed pass-throughs, e.g.
  `weapon_damage` getter returns `inventory.weapon_damage`, and remove the private `_weapon_damage`
  backing field (same for `armor`/`_armor`). Keep the `weapon_damage_changed` / `armor_changed` signals
  firing by connecting them to `inventory.changed`, so `get_damage()`, `get_total_damage()`,
  `get_armor()` and `hurt()` keep working without changes.
- `load_state(...)` keeps its current `a_damage` / `a_armor` parameters, but now forwards them into
  `inventory.equip_weapon("", a_damage)` / `inventory.equip_armor("", a_armor)` instead of assigning
  `_weapon_damage` / `_armor` directly (empty `item_id` until Phase 3 adds real ids).
- Update any existing GUT tests that poke `_weapon_damage` / `_armor` directly to go through the public
  setters/`inventory` instead.

### Phase 3 — Give equipment an identity, update item scripts

- Add `@export var item_id: String = ""` to `items/sword.gd` and `items/helmet.gd`, and set it per scene
  (e.g. `sword_iron.tscn` → `item_id = "sword_iron"`, `sword_stone.tscn` → `item_id = "sword_stone"`,
  likewise for the three helmet tiers). This is the missing piece identified earlier: today a tier is
  only a scene name + sprite frame, with no runtime identity, so the inventory/UI has nothing to show
  which tier is equipped.
- `Sword.execute()` / `Helmet.execute()` change from writing `CharacterManager.current.weapon_damage`
  directly to calling `CharacterManager.current.inventory.equip_weapon(item_id, damage)` /
  `equip_armor(item_id, armor)`. Keep the existing sound-on-pickup and `queue_free()` calls; the
  "only replace if better" check now lives inside `Inventory.equip_weapon/equip_armor` instead of the
  item script.
- `HealingPotion.execute()` changes from healing immediately to calling
  `CharacterManager.current.inventory.add_potion()`; only play the pickup sound and `queue_free()` if
  `add_potion()` returned `true`, otherwise play a "can't carry more" cue and leave the potion item in
  the world so the pickup isn't silently lost.
- `Lighter.execute()` / `EyeOfEnder.execute()` are not touched.
- Add the `use_potion` input action in `project.godot` (`InputMap`), wired wherever player input is
  handled (likely a new check next to the existing `Input.is_action_just_pressed("quest_log")` pattern
  in a relevant `_process`), calling `CharacterManager.current.inventory.use_potion()`.

### Phase 4 — Character Sheet screen

- Add `GameSession.DisplayState.CHARACTER_SHEET` to the enum in `classic/game_session.gd`, next to
  `QUEST_LOG`. No other change needed in `game_session.gd` — `is_simulation_running()` already treats
  any non-`NONE` state as paused.
- Add the `character_sheet` input action in `project.godot`.
- Add `gui/character_sheet_gui.gd` + `gui/character_sheet_gui.tscn`, structurally copying
  `quests/quest_log_gui.gd`'s `_process`/`_on_display_state_changed`/`_show_menu`/`_hide_menu` pattern,
  but toggling `DisplayState.CHARACTER_SHEET` on the `character_sheet` action instead of `QUEST_LOG` on
  `quest_log`. Its scene embeds one `StatsSheet` instance unchanged (for HP/damage/armor) plus new
  `Label`/`TextureRect` nodes for weapon icon, armor icon, potion count, a "Use Potion" `Button`, and
  read-only Lighter/Eyes-of-Ender indicators fed by `GameSession.has_lighter_changed` /
  `eyes_of_ender_changed` and `Inventory.changed`.
- Add one `CharacterSheetGui` instance to each level scene (`classic/overworld.tscn`, `classic/nether.tscn`,
  `classic/end.tscn`, `procedural/proc_gen_world.tscn`) under `UI`, next to the existing
  `QuestLogGui` instance. `gui/pause_menu.tscn` / `pause_gui.tscn` stay untouched.

### Phase 5 — Persistence (weapon/armor only)

- Extend `SaveManager.save_character()` to also persist `character.inventory.weapon_item_id`,
  `weapon_damage`, `armor_item_id`, `armor_value`.
- Extend `Character.load_state(...)`'s signature with `a_weapon_item_id: String` and
  `a_armor_item_id: String` alongside the existing `a_damage` / `a_armor`, forwarding all four into
  `inventory.equip_weapon(...)` / `equip_armor(...)`.
- Deliberately do **not** add `potion_count`, `has_lighter`, or `eyes_of_ender` to the save payload —
  these stay session-only, matching current `GameSession.reset()` behavior.
- Add a GUT save/load round-trip test: save a character with a potion and an equipped iron sword, reload,
  assert the sword/damage survived but `potion_count` is back to `0`.

### Phase 6 — Manual playtest pass

- Pick up a stone sword then an iron sword: only the iron one should take effect (and vice versa should
  be rejected).
- Pick up potions until the slot is full, confirm the "can't carry more" feedback, then use one mid-fight
  and confirm healing only happens on the explicit action.
- Open/close the character sheet with the `character_sheet` action, confirming the simulation pauses and
  resumes correctly, and that it does not interfere with the quest log or pause menu.
- Save, reload, and confirm weapon/armor persisted while potions/lighter/eyes of ender reset.

## Why this shape

Fixed slots keep the UI tiny and unambiguous for young kids (no sorting/dragging). Turning potions into
a counted, manually-used resource is the one change that makes the inventory *matter* during play (the
player must decide when to heal), while weapon/armor keep today's "auto-equip if better" simplicity so
progression still feels automatic and rewarding. This also lays the groundwork described in the earlier
roadmap discussion (character sheet, TNT/lighter, future biome loot) without over-building for a feature
that isn't requested yet (no trading/dropping/multiple loadouts).
