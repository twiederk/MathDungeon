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
- `StatsSheet` (`gui/stats_sheet.gd`) already shows HP, damage and armor numbers — this is the seed of
  the "character sheet" and will be extended to show equipped gear and consumables.
- `Character` (`characters/character.gd`) holds `weapon_damage`, `armor`, `hit_points` and is saved via
  `SaveManager.save_character()`.

## Scope

### In scope
- Weapon slot, Armor slot (both fixed, exactly one item each).
- A small fixed number of Consumable slots (start with 1 type: Healing Potion, stacked as a count).
- Manual "use" action for consumables (keybind + inventory UI button).
- Equip/replace flow for Weapon and Armor, using the existing "only replace if better" rule to keep
  decisions simple for kids (no drag-and-drop, no selling/discarding UI).
- Inventory UI panel reachable from the pause menu, plus a read-only summary on the character sheet.
- Save/load of inventory state (equipped item id/tier, potion count) via `SaveManager`.

### Out of scope (future work, not part of this feature)
- Trading, dropping items back into the world, or multiple weapon/armor loadouts.
- Key items (Lighter, Eye of Ender) moving into the slot system — they remain `GameSession` flags, but
  get a read-only row in the inventory UI for visibility/motivation.
- Stat bonuses beyond damage/armor/healing (e.g. speed items) — can reuse the same slot pattern later.

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

- New scene `gui/inventory_widget.tscn` / `inventory_widget.gd`:
  - Weapon slot icon + damage number.
  - Armor slot icon + armor number.
  - Potion slot icon + count (e.g. "x3") + "Use" button.
  - Read-only row: Lighter (yes/no icon), Eyes of Ender (count) — reuses `GameSession` signals already
    in place (`has_lighter_changed`, `eyes_of_ender_changed`).
- Add the inventory widget as a tab/section in `gui/pause_menu.tscn` next to the existing quest log, and
  embed a compact version inside `gui/stats_sheet.tscn` so the "character sheet" shows gear at a glance.
- All UI listens to `Inventory.changed` (and existing `GameSession` signals) to refresh, following the
  existing signal-driven pattern used by `weapon_damage_changed` / `armor_changed`.

### Persistence

- `SaveManager.save_character()` / the character load path gain two or three extra fields: equipped
  weapon id + damage, equipped armor id + armor value, potion count. Mirrors the existing
  `load_state(...)` parameter style in `character.gd`.

## Implementation steps

1. Add `Inventory` class with weapon/armor/potion state + signals; unit test with GUT
   (`test/test_inventory.gd`): equip only replaces when strictly better, potion add/use respects
   `MAX_POTIONS` and zero floor.
2. Wire `Character` to own an `Inventory` and expose `weapon_damage`/`armor` as pass-throughs; update
   existing character tests if they poke `_weapon_damage`/`_armor` directly.
3. Update `Sword`, `Helmet`, `HealingPotion` `execute()` to go through `inventory`; add the `use_potion`
   input action in `project.godot`.
4. Build `inventory_widget.tscn`/`.gd`; hook into `pause_menu.tscn` and `stats_sheet.tscn`.
5. Extend `SaveManager` save/load + `Character.load_state(...)` signature for the new fields; add a
   save/load round-trip GUT test.
6. Manual playtest pass: pick up two swords in a row (only better one equips), fill potion slot to max
   and verify pickup feedback, use potion mid-fight, confirm pause-menu + stats sheet reflect state, and
   confirm save/reload restores inventory correctly.

## Why this shape

Fixed slots keep the UI tiny and unambiguous for young kids (no sorting/dragging). Turning potions into
a counted, manually-used resource is the one change that makes the inventory *matter* during play (the
player must decide when to heal), while weapon/armor keep today's "auto-equip if better" simplicity so
progression still feels automatic and rewarding. This also lays the groundwork described in the earlier
roadmap discussion (character sheet, TNT/lighter, future biome loot) without over-building for a feature
that isn't requested yet (no trading/dropping/multiple loadouts).
