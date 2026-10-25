# Feature: Goods in the Inventory (GoodResource)

## Goal
Introduce a `GoodResource` type (parallel to `WeaponResource`/`ArmorResource`) for
non-equipment items — eye of ender, healing potion, lighter — tracked in a new
`Inventory.goods` array. `potion_count` is removed in favor of `get_potion_count()`.
`eyes_of_ender`/`has_lighter` (+ their signals) move from `GameSession` to `Character`.

## Decisions (confirmed with user)
- `eyes_of_ender` / `has_lighter` stay **session-only**, same as `potion_count` today —
  not written to the character save file. This already works for free: `start_menu.gd`
  reloads `CharacterManager.current` via `SaveManager.load_and_activate_character()`
  every time the start menu is shown, which creates a brand-new `Character`/`Inventory`
  (so `goods`, `eyes_of_ender`, `has_lighter` naturally reset). `GameSession.reset()`
  simply stops touching them — no replacement reset call is needed.
- `add_potion(resource: GoodResource)` takes the picked-up item's own `GoodResource`
  (mirrors how `Sword`/`Helmet` pass their own `weapon_resource`/`armor_resource` into
  `equip_weapon`/`equip_armor`). `use_potion()` stays parameterless (it just removes one
  matching entry from `goods`).
- Signal wiring: assume a single `Character` instance per running session (as today).
  Callers keep connecting once in `_ready()` to `CharacterManager.current.<signal>`,
  same pattern as the current one-time `GameSession` connections. No rebind-on-switch
  logic is added.
- `goods` holds **all three** pickups (eye of ender, healing potion, lighter) as
  `GoodResource` entries — this is in addition to (not instead of) the dedicated
  `Character.eyes_of_ender` (int) / `Character.has_lighter` (bool) convenience fields,
  which keep their current signal-emitting behavior, just relocated from `GameSession`
  to `Character`.

## Phase 1 — `GoodResource` + data files
- Add `items/good_resource.gd`:
  ```gdscript
  class_name GoodResource
  extends Resource

  const ICON_GRID_SIZE: int = 16

  @export var id: String = ""
  @export var name: String = ""
  @export var damage: int = 0
  @export var icon_texture: Texture2D
  @export var icon_frame: int = 0

  func get_icon() -> Texture2D:
      if icon_texture == null:
          return null
      var atlas := AtlasTexture.new()
      atlas.atlas = icon_texture
      var cell := icon_texture.get_size() / Vector2(ICON_GRID_SIZE, ICON_GRID_SIZE)
      var col := icon_frame % ICON_GRID_SIZE
      var row := icon_frame / ICON_GRID_SIZE
      atlas.region = Rect2(col * cell.x, row * cell.y, cell.x, cell.y)
      return atlas
  ```
  (`get_icon()` mirrors `WeaponResource`/`ArmorResource` for consistency with the item
  icon feature; `damage` is unused for goods today but kept exactly as specified.)
- Create three `.tres` resources matching the existing pickup scenes' `Sprite2D` frames
  (`items.png`, 16x16 grid):

  | Resource | id | name | icon_frame |
  |---|---|---|---|
  | `items/eye_of_ender_good.tres` | `eye_of_ender` | `Enderauge` | 155 |
  | `items/healing_potion_good.tres` | `healing_potion` | `Heiltrank` | 152 |
  | `items/lighter_good.tres` | `lighter` | `Feuerzeug` | 5 |

  (Named `*_good.tres` to avoid clashing with the existing `.tscn` of the same base name
  in the same folder, same reasoning as `sword_wood.tres` next to `sword_wood.tscn` — but
  those don't collide since extensions differ; still using a distinct suffix here makes
  the resource's purpose explicit next to the pickup scene.)
- The `id` string `"healing_potion"` becomes a contract: `Inventory.get_potion_count()`
  and `Inventory.use_potion()` identify potions by `resource.id == "healing_potion"`, so
  this value must match exactly.

## Phase 2 — `ItemCatalog`
- Add to `items/item_catalog.gd`:
  ```gdscript
  @export var goods: Array[GoodResource] = []

  func get_good(good_id: String) -> GoodResource:
      for good in goods:
          if good.id == good_id:
              return good
      return null
  ```
- Register the three new `.tres` resources in `items/item_catalog.tres`.

## Phase 3 — `Inventory`
- Replace `var potion_count: int = 0` with `var goods: Array[GoodResource] = []`.
- Add:
  ```gdscript
  const HEALING_POTION_ID: String = "healing_potion"

  func equip_good(resource: GoodResource) -> void:
      goods.append(resource)
      changed.emit()

  func add_potion(resource: GoodResource) -> bool:
      if get_potion_count() >= MAX_POTIONS:
          return false
      goods.append(resource)
      changed.emit()
      return true

  func use_potion() -> bool:
      for i in goods.size():
          if goods[i].id == HEALING_POTION_ID:
              goods.remove_at(i)
              changed.emit()
              return true
      return false

  func get_potion_count() -> int:
      var count := 0
      for good in goods:
          if good.id == HEALING_POTION_ID:
              count += 1
      return count
  ```
- Remove all direct reads of `inventory.potion_count` elsewhere (see Phase 5/6).

## Phase 4 — Pickup scripts & scenes
- `items/eye_of_ender.gd`:
  ```gdscript
  class_name EyeOfEnder
  extends Item

  @export var good_resource: GoodResource

  func execute() -> void:
      CharacterManager.current.inventory.equip_good(good_resource)
      CharacterManager.current.eyes_of_ender += 1
      Sound.play(Sound.victory)
      queue_free()
  ```
- `items/lighter.gd`:
  ```gdscript
  class_name Lighter
  extends Item

  @export var good_resource: GoodResource

  func execute() -> void:
      CharacterManager.current.inventory.equip_good(good_resource)
      CharacterManager.current.has_lighter = true
      Sound.play(Sound.pickup_lighter)
      queue_free()
  ```
- `items/healing_potion.gd`:
  ```gdscript
  class_name HealingPotion
  extends Item

  @export var good_resource: GoodResource

  func execute() -> void:
      if CharacterManager.current.inventory.add_potion(good_resource):
          Sound.play(Sound.pickup_potion)
          queue_free()
      else:
          Sound.play(Sound.pickup_potion, 0.6)
  ```
- Update `eye_of_ender.tscn`, `healing_potion.tscn`, `lighter.tscn` to add an
  `ext_resource` for their respective new `.tres` and set `good_resource` on the root
  node (their existing `Sprite2D` nodes/frames stay untouched).

## Phase 5 — Move `eyes_of_ender`/`has_lighter` to `Character`
- `classic/game_session.gd`: remove `signal eyes_of_ender_changed`, `signal
  has_lighter_changed`, `var eyes_of_ender`, `var has_lighter`, and the two lines in
  `reset()` that touch them.
- `characters/character.gd`: add
  ```gdscript
  signal eyes_of_ender_changed
  signal has_lighter_changed

  var eyes_of_ender: int = 0:
      set(value):
          eyes_of_ender = value
          eyes_of_ender_changed.emit()

  var has_lighter: bool = false:
      set(value):
          has_lighter = value
          has_lighter_changed.emit()
  ```
- Update consumers from `GameSession.eyes_of_ender(_changed)` /
  `GameSession.has_lighter(_changed)` to `CharacterManager.current.eyes_of_ender(_changed)`
  / `CharacterManager.current.has_lighter(_changed)`:
  - `quests/achievement_manager.gd` (`_ready()`, `_on_eyes_of_ender_changed`,
    `_on_has_lighter_changed`)
  - `locations/end_portal.gd` (`_ready()`, `_on_eyes_of_ender_changed`,
    `_display_eyes_of_ender()`, `_activate_portal()`)
  - `locations/nether_portal.gd` (`_on_outer_area_2d_body_entered`)
  - `gui/character_sheet_gui.gd` (`_refresh()`: `inventory.potion_count` →
    `inventory.get_potion_count()`, `GameSession.has_lighter` →
    `CharacterManager.current.has_lighter`, `GameSession.eyes_of_ender` →
    `CharacterManager.current.eyes_of_ender`)

## Phase 6 — Update existing tests
- `test/test_Inventory.gd`: replace `potion_count` assertions with
  `get_potion_count()`; update `add_potion()` calls to pass a `GoodResource`.
- `test/test_HealingPotion.gd`: same `potion_count` → `get_potion_count()` change.
- `test/test_SaveManager.gd`: `loaded.inventory.potion_count` →
  `loaded.inventory.get_potion_count()`.
- `test/test_GameSession.gd`: remove assertions on `GameSession.eyes_of_ender` /
  `GameSession.has_lighter`; move equivalent assertions to a `Character`-focused test
  (new or existing `test_Character.gd` if present).
- `test/test_AchievementManager.gd`, `test/test_QuestLog.gd`, `test/test_Lighter.gd`:
  replace `GameSession.eyes_of_ender` / `GameSession.has_lighter` with
  `CharacterManager.current.eyes_of_ender` / `CharacterManager.current.has_lighter`.
- Add new tests:
  - `GoodResource.get_icon()` region calculation (mirrors
    `WeaponResource`/`ArmorResource` icon tests if any exist).
  - `Inventory.equip_good()` appends to `goods` and emits `changed`.
  - `Inventory.add_potion()` / `use_potion()` / `get_potion_count()` against the `goods`
    array (replacing the old `potion_count`-based tests).

## Phase 7 — Verify
- Run `cmd /c "test_ING.bat < nul"` and fix any remaining fallout.
- Manual check in editor: pick up an eye of ender, a potion, and the lighter in a running
  game; confirm `CharacterSheetGui` potion/lighter/eyes labels still update correctly.
