# Feature: Inventory Items as Resources

## Goal

Replace the loose `item_id` + raw `damage` / `armor` integers introduced by the first inventory feature
with real Godot resources (`WeaponResource`, `ArmorResource`). This gives every weapon and armor tier a
single authoritative definition — id, display name and stat value live in one `.tres` file instead of
being spread across a scene's export values and a hand-typed id string.

## Decisions (confirmed)

1. **Catalog lookup for persistence.** The save file stores only the item `id`; a new `ItemCatalog`
   `.tres` resolves that id back to the matching `WeaponResource` / `ArmorResource` on load. This
   mirrors the existing `PortraitCatalog` pattern already used for `portrait_id`.
2. **"Only equip if better" stays.** `equip_weapon(resource)` returns `false` when the incoming
   resource's `damage` is not greater than the currently equipped one (same for armor).
3. **`get_total_damage()` is merged into `get_damage()`.** `get_damage()` becomes the single public
   damage accessor and includes the Wolf companion bonus; `get_total_damage()` is deleted.
4. **Signals are renamed** to `damage_changed` / `armor_changed`, matching the new
   `base_damage` / `base_armor` property names.

## Current state (for reference)

- `Inventory` (`characters/inventory.gd`) stores `weapon_item_id: String` + `weapon_damage: int` and
  `armor_item_id: String` + `armor_value: int` as four independent fields. `equip_weapon(item_id, damage)`
  / `equip_armor(item_id, armor)` apply the "only if better" check and emit `changed`.
- `Character` (`characters/character.gd`) exposes `weapon_damage` / `armor` as computed pass-throughs
  into the inventory, emits `weapon_damage_changed` / `armor_changed` from `_on_inventory_changed()`,
  and has both `get_damage()` (weapon only) and `get_total_damage()` (weapon + Wolf bonus).
- `Sword` (`items/sword.gd`) and `Helmet` (`items/helmet.gd`) each carry two separate exports —
  `damage`/`armor` plus `item_id` — which must be kept in sync by hand in every tier scene
  (`sword_stone.tscn`, `sword_iron.tscn`, `helmet_wood.tscn`, `helmet_stone.tscn`, `helmet_iron.tscn`).
- `Allay.execute()` (`companions/allay.gd`) does `CharacterManager.current.armor += 1`, which today
  routes through `Inventory.equip_armor("", value)` — it silently overwrites the equipped helmet's
  `armor_item_id` with an empty string. Moving it to `base_armor` fixes that bug as a side effect.
- `SaveManager.save_character()` persists `weapon_damage`, `weapon_item_id`, `armor`, `armor_item_id`
  as four flat values; `Character.load_state(...)` takes them back as four parameters.
- `EnemyStats` (`enemies/enemy_stats.gd`) is the existing in-repo example of a `class_name X extends
  Resource` with `@export` fields backed by per-instance `.tres` files — the new resources follow it.

## Scope

### In scope
- New `WeaponResource` and `ArmorResource` resource scripts plus one `.tres` per existing tier.
- New `ItemCatalog` resource for id -> resource lookup during load.
- `Inventory` storing `weapon_resource` / `armor_resource` instead of four loose fields.
- `Character.base_damage` / `Character.base_armor` as the character's own (companion- and
  equipment-independent) stats, with `get_damage()` / `get_armor()` summing base + equipped resource.
- `Allay` raising `base_armor` instead of writing into the equipment slot.
- `SaveManager` persisting `base_damage`, `base_armor` and the two item ids.

### Out of scope (future work)
- Icons/textures on the resources — the character sheet keeps showing text. (`WeaponResource.name` is
  already enough to display "Eisenschwert" instead of the raw `sword_iron` id, which is the visible win.)
- Any new item tiers or item types beyond the five that exist today.
- Potions becoming resources — `potion_count` stays a plain int.
- Rebalancing damage/armor numbers; every tier keeps its current value.

## Design

### New resources

`items/weapon_resource.gd`:

```gdscript
class_name WeaponResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var damage: int = 0
```

`items/armor_resource.gd`:

```gdscript
class_name ArmorResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var armor: int = 0
```

Concrete `.tres` files, keeping today's stat values:

| File | id | name | value |
| --- | --- | --- | --- |
| `items/sword_stone.tres` | `sword_stone` | Steinschwert | `damage = 2` |
| `items/sword_iron.tres` | `sword_iron` | Eisenschwert | `damage = 3` |
| `items/helmet_wood.tres` | `helmet_wood` | Holzhelm | `armor = 1` |
| `items/helmet_stone.tres` | `helmet_stone` | Steinhelm | `armor = 2` |
| `items/helmet_iron.tres` | `helmet_iron` | Eisenhelm | `armor = 3` |

`items/item_catalog.gd` + `items/item_catalog.tres`, modelled directly on `PortraitCatalog`:

```gdscript
class_name ItemCatalog
extends Resource

@export var weapons: Array[WeaponResource] = []
@export var armors: Array[ArmorResource] = []

func get_weapon(id: String) -> WeaponResource
func get_armor(id: String) -> ArmorResource
```

### Item scenes

- `items/sword.gd` drops its `damage` and `item_id` exports in favour of
  `@export var weapon_resource: WeaponResource`. `execute()` calls
  `CharacterManager.current.inventory.equip_weapon(weapon_resource)`.
- `items/helmet.gd` likewise gets `@export var armor_resource: ArmorResource` and calls
  `equip_armor(armor_resource)`.
- Each tier scene assigns its matching `.tres` to that one export, so the stat value can no longer
  drift from the id.

### Inventory

```gdscript
var weapon_resource: WeaponResource = null
var armor_resource: ArmorResource = null
var potion_count: int = 0

func equip_weapon(resource: WeaponResource) -> bool   # false if not strictly better
func equip_armor(resource: ArmorResource) -> bool
func get_weapon_damage() -> int                        # 0 when nothing equipped
func get_armor_value() -> int
```

`equip_weapon()` returns `false` when `resource == null` or `resource.damage <= get_weapon_damage()`,
otherwise assigns and emits `changed`. `get_weapon_damage()` / `get_armor_value()` keep the null check
in one place so callers never have to guard an empty slot.

### Character

- `weapon_damage` and `armor` are **replaced** by plain stored fields `base_damage: int = 1` and
  `base_armor: int = 0`. They are no longer pass-throughs into the inventory; the inventory contributes
  separately via its equipped resources.
- `get_damage()` returns `base_damage + inventory.get_weapon_damage() + (wolf_count * WOLF_DAMAGE)`.
- `get_armor()` returns `base_armor + inventory.get_armor_value()`.
- `get_total_damage()` is deleted; all call sites move to `get_damage()`.
- Signals `weapon_damage_changed` / `armor_changed` become `damage_changed` / `armor_changed`, emitted
  from `_on_inventory_changed()`, from the `base_damage` / `base_armor` setters, and from
  `add_companion()` (which affects `get_damage()` through the Wolf bonus).
- `_init()` no longer seeds `inventory.weapon_damage = 1` — the starting damage of 1 now lives in
  `base_damage`, which is where it conceptually belongs.

### Companions

- `Allay.execute()` changes from `CharacterManager.current.armor += 1` to
  `CharacterManager.current.base_armor += 1`. This is the behavioural fix noted above: the Allay bonus
  no longer clobbers the equipped helmet's slot.

### Persistence

`SaveManager.save_character()` payload changes from `weapon_damage` / `armor` /`weapon_item_id` /
`armor_item_id` to:

```gdscript
"base_damage": character.base_damage,
"base_armor": character.base_armor,
"weapon_item_id": character.inventory.get_weapon_id(),
"armor_item_id": character.inventory.get_armor_id(),
```

`_character_from_data()` resolves the two ids through `ItemCatalog` before calling `load_state(...)`,
whose signature becomes `(..., a_base_damage: int, a_weapon: WeaponResource, a_base_armor: int,
a_armor: ArmorResource, a_companions)`.

**Backward compatibility:** old save files have no `base_damage` / `base_armor` keys, and their
`weapon_damage` / `armor` values were *totals* (base + equipment). The load path reads
`data.get("base_damage", data.get("weapon_damage", 1))` as a fallback, so an old save keeps its total as
the new base value. The character is slightly stronger than a fresh equivalent until the next pickup
overwrites the slot — acceptable for a kids' game and far simpler than a real migration pass. The
`weapon_item_id` / `armor_item_id` keys already exist in current saves and resolve through the catalog
as normal; unknown ids resolve to `null` (empty slot).

## Implementation phases

### Phase 1 — Resource classes and `.tres` files

- Add `items/weapon_resource.gd` and `items/armor_resource.gd` with the exports shown above.
- Add the five `.tres` files with their ids, German display names and current stat values.
- Add `items/item_catalog.gd` + `items/item_catalog.tres` listing all five resources.
- Add `test/test_ItemCatalog.gd` (GUT): a known id resolves to the right resource with the expected
  damage/armor, and an unknown id returns `null` (mirrors `test_PortraitCatalog.gd`).
- Nothing else references these yet — this phase is purely additive and independently testable.
- Remember to run `Godot_v4.7-stable_win64.exe --path . --headless --import` after adding the new
  `class_name` scripts so the class cache and `.uid` files are generated.

### Phase 2 — `Inventory` stores resources

- Replace the four fields with `weapon_resource` / `armor_resource`; change `equip_weapon()` /
  `equip_armor()` to take a resource; add `get_weapon_damage()` / `get_armor_value()` and
  `get_weapon_id()` / `get_armor_id()` (empty string when the slot is empty, for the save payload).
- Rewrite `test/test_Inventory.gd`'s weapon/armor cases to build resources via `WeaponResource.new()` /
  `ArmorResource.new()`. The potion tests are untouched.
- `Character` will not compile against the new `Inventory` until Phase 3, so Phases 2 and 3 land together.

### Phase 3 — `Character` base stats

- Replace the `weapon_damage` / `armor` computed properties with stored `base_damage` / `base_armor`
  whose setters emit the renamed signals and call `SaveManager.save_character(self)`.
- Implement `get_damage()` as base + equipment + Wolf bonus; delete `get_total_damage()`.
- Implement `get_armor()` as base + equipment.
- Rename the signals and update `classic/world_level.gd`'s two `connect()` calls.
- Update every `get_total_damage()` call site to `get_damage()`: `classic/world_level.gd` (2),
  `gui/character_widget.gd`, `gui/character_sheet_gui.gd`, `quiz/quiz_dialog.gd`, and
  `test/test_Character.gd`.
- Update every `character.armor` read to `character.get_armor()`: `classic/world_level.gd` (2),
  `gui/character_widget.gd`, `gui/character_sheet_gui.gd`.
- Update `test/test_Character.gd`, `test/test_character_create_dialog.gd`, `test/test_Sword.gd` and
  `test/test_Helmet.gd` to the new property and accessor names, and add cases asserting that
  `get_damage()` / `get_armor()` really sum base + equipped resource.

### Phase 4 — Item scenes and Allay

- Swap `items/sword.gd` / `items/helmet.gd` over to the single `weapon_resource` / `armor_resource`
  export and the new `equip_*` signature.
- Assign the matching `.tres` in all five tier scenes, removing the old `damage` / `armor` / `item_id`
  scene overrides.
- Change `companions/allay.gd` to `base_armor += 1`.
- Add a GUT test asserting the Allay bonus leaves `inventory.armor_resource` untouched — this is the
  regression the change is meant to prevent.

### Phase 5 — Persistence

- Update `SaveManager.save_character()` to the new payload and `_character_from_data()` to resolve ids
  through `ItemCatalog` (preloaded as a const, like `Character.PORTRAIT_CATALOG`).
- Update `Character.load_state(...)` to the new signature and its call sites in `test/test_Character.gd`
  and `test/test_SaveManager.gd`.
- Extend the existing round-trip test: save a character with a non-default `base_armor`, an equipped
  iron sword and a potion; reload and assert the sword resource, its damage and `base_armor` survived
  while `potion_count` is back to `0`.
- Add a test for the legacy fallback: hand-write a save dictionary containing only the old
  `weapon_damage` / `armor` keys, load it, and assert the values land in `base_damage` / `base_armor`
  rather than being lost.

### Phase 6 — Manual playtest pass

- Pick up a stone sword then an iron sword and confirm the character sheet now shows the display name
  ("Eisenschwert") and that the downgrade is still rejected.
- Collect an Allay, then pick up a helmet, and confirm both bonuses stack instead of overwriting.
- Save, reload, and confirm weapon/armor/base stats persisted while potions reset.
- Load a character saved *before* this change and confirm it still opens with sensible stats.

## Why this shape

Today a tier's identity (`item_id`), its stat (`damage`) and its display text are three separate things
that can silently disagree; folding them into one resource makes a tier a single editable object and
removes the hand-synced duplication. Splitting `base_damage` / `base_armor` away from equipment is what
makes the Allay bug fixable at all — permanent character bonuses and swappable gear are genuinely
different concepts and were only conflated because both were once plain ints on `Character`. The catalog
keeps save files small and human-readable (ids, not paths) and reuses a lookup pattern already proven in
this repo by `PortraitCatalog`.
