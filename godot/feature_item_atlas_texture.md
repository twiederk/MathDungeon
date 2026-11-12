# Feature: Item Atlas Textures

## Goal

Replace item sprite-sheet frame selection with `AtlasTexture` regions in `res://items`,
`Item`, `WeaponResource`, `ArmorResource`, `GoodResource`, and `CharacterSheetGui`.
Introduce and populate atlas textures before removing the legacy resource fields.
Keep every implementation phase independently usable.

## Starting Constraints

- The nine item scenes in `res://items` use `items.png` with a 16-by-16 sprite grid.
  The wood helmet implicitly uses frame 0. The three scenes in `res://procedural/items`
  already use `AtlasTexture` regions on their `Sprite2D` nodes.
- `Item` currently has no texture or frame field; its subclasses attach item resources,
  while the scenes own the world sprite. Do not invent a legacy `Item` field to remove.
- The three resource classes export `icon_texture: Texture2D` and `icon_frame` and
  construct an atlas in `get_icon()`. The character sheet calls that method for weapons,
  armor, and goods. Companion icons use a separate creature sheet and are out of scope.
- Procedural scenes reference the same item resources as classic scenes but use different
  world artwork. Keep scene sprites independent of resource icons so the procedural art
  does not change. Preserve resource IDs, names, stats, catalog references, and save data.

## Follow-up Decisions

- A game session uses either classic items or RPG items, not a mixture. Give each of the
   three procedural item scenes its own resource with an `rpg_items.png` atlas icon and
   add those resources to the item catalog. Keep classic IDs unchanged and assign unique
   IDs to the RPG resources.
- Replace the character sheet's separate potion, lighter, and ender-eye rows with a goods
   bag. Show one atlas icon and quantity per distinct good resource, without filtering or
   grouping by item ID. Each entry in `Inventory.goods` represents one instance.
- Remove the maximum potion limit. Using a healing potion removes one matching instance
   from the goods array. Identify healing potions by a gameplay type on `GoodResource`,
   not by a classic or RPG item ID.
- Preserve existing equipment replacement rules and saves. Equipment is saved by ID;
   goods are currently session-only and adding them to the catalog does not persist them.

## Phase 1 - Introduce Atlas Icons

**Status:** Implemented; manual validation pending.

1. Add an exported `icon_atlas: AtlasTexture` to each of `WeaponResource`,
   `ArmorResource`, and `GoodResource`, alongside the existing fields.
2. Make `get_icon()` return `icon_atlas` when present; otherwise retain the existing
   `icon_texture` and `icon_frame` conversion and null behavior. This keeps old resources
   and callers working throughout the transition.
3. Populate `icon_atlas` in all nine item `.tres` resources with an `AtlasTexture` using
   the existing `items.png` and the region corresponding to the old frame. Keep the
   legacy fields for now, including the implicit frame 0 on the wood helmet.
4. Compute regions using the actual imported texture dimensions: cell size is the sheet
   size divided by 16 in each direction, column is `frame % 16`, and row is integer
   `frame / 16`. Preserve these frame mappings: helmets wood/stone/iron 0/1/2, lighter 5,
   swords wood/stone/iron 64/65/66, healing potion 152, and eye of ender 155.

### Validation

- Validate manually for all three resource classes: atlas precedence, legacy fallback
   including frame 0, and a missing icon returning null.
- Manually check every catalog resource's atlas source and region against its original
   frame, and verify catalog lookup and inventory behavior still work.

**Done when:** all item resource icons are populated and existing callers continue to
work with either new or legacy resource data.

## Phase 2 - Migrate World Items and Item

**Status:** Implemented; manual validation pending.

1. Replace each classic item scene's `Sprite2D` texture and frame settings with an
   `AtlasTexture` subresource over `items.png`, using the corresponding original frame
   region. Remove `hframes`, `vframes`, and `frame` overrides, including the implicit
   default frame for the wood helmet. Preserve scene identities, scripts, resource
   assignments, collision shapes, transforms, and pickup behavior.
2. Give `Item` a typed `AtlasTexture` accessor for its scene's `Sprite2D.texture`, with
   a null-safe result for an absent sprite or non-atlas texture. Do not add a second
   exported texture that duplicates the sprite's scene-owned texture or overwrite it
   from the inventory resource. Keep existing pickup and `execute()` behavior unchanged.
3. Leave the existing procedural atlas regions and artwork intact; verify those shared
   `Item` subclasses work with the same accessor and retain their original visuals.

### Validation

- Manually instantiate all nine classic scenes and all three procedural item scenes.
   Check the sprite texture is an atlas with the expected source and region, frame grid is
   at its defaults, and the `Item` accessor returns the same texture.
- Manually check the accessor's missing/non-atlas case and exercise item pickups and loot.
   Visually compare classic and procedural items to their pre-migration appearance.

**Done when:** item world sprites use regions without frame selection, and procedural
sprites and pickup behavior remain unchanged.

## Phase 3 - Simplify Character Sheet and Remove Legacy Fields

**Status:** Implemented; manual validation pending.

1. Change weapon, armor, and good icon rendering in `CharacterSheetGui` to consume
   `icon_atlas` directly. Preserve null-icon behavior, empty equipment visibility, good
   counts, icon sizing, labels, and repeated refresh behavior. Leave companion icon
   construction unchanged because it is not an item resource.
2. Once every shipped resource and caller has migrated, remove `icon_texture`,
   `icon_frame`, `ICON_GRID_SIZE`, and the now-unneeded `get_icon()` conversion from all
   three resource classes. Remove the legacy properties from the nine `.tres` files in
   the same phase. The underlying atlas source remains a `Texture2D`, as Godot requires.
3. Search the project for remaining item-specific references to the removed fields and
   method, and migrate any tests or consumers found. Do not change unrelated sprite sheets.

### Validation

- Manually check character sheet rows with and without equipment, goods of each displayed
   kind, repeated goods, null icons, and repeated refreshes; verify displayed textures are
   the resource atlases and companion icons still work.
- Manually load all item scenes and catalog resources after legacy fields are removed;
   confirm no missing properties or resource-loading errors. Verify an existing saved
   character loads the same equipment by ID, and exercise pickups and the character sheet
   in game. Goods remain session-only.

**Done when:** no item resource depends on a frame number or constructs an icon atlas at
runtime, the character sheet uses the stored atlas directly, and gameplay and saved
inventories retain their existing behavior.

## Phase 4 - Add RPG Resources and Potion Types

**Status:** Implemented; manual validation pending.

1. Create a separate `WeaponResource`, `ArmorResource`, and `GoodResource` for the
   procedural wood sword, wood helmet, and healing potion, respectively. Use unique IDs
   such as `rpg_sword_wood`, `rpg_helmet_wood`, and `rpg_healing_potion`; retain the
   existing classic IDs, names, damage, armor values, and potion behavior.
2. Set their atlas icons to `res://procedural/items/rpg_items.png`, using the corresponding
   scene regions: sword `Rect2(16, 1712, 16, 16)`, helmet `Rect2(32, 368, 16, 16)`,
   and potion `Rect2(224, 576, 16, 16)`. Assign each new resource to its procedural scene
   and add it to the appropriate array in `ItemCatalog`. Keep the world sprites unchanged.
3. Add a gameplay type to `GoodResource`, with a non-potion default and a healing-potion
   value. Assign the healing-potion type to both classic and RPG potion resources. Keep
   lighter and ender-eye behavior unchanged.
4. Remove `MAX_POTIONS` and its limit check. Identify healing potions by type instead of
   `HEALING_POTION_ID` when counting and consuming them. Using a potion removes the first
   matching instance and emits the existing inventory change signal; reject null or
   non-potion inputs to `add_potion()`. Preserve the existing full-health behavior.
5. Update existing tests and fixtures that rely on the potion ID or limit to reflect the
   new type and unlimited capacity. The character sheet's old potion filter must also be
   updated to filter by type temporarily so this phase remains independently usable;
   Phase 5 replaces that filter with the goods bag.

### Validation

- Manually check the three RPG scene resources, catalog lookups, IDs, icons, stats, and
  pickups. Verify existing classic equipment saves still resolve and RPG equipment saves
  reload with the RPG icon.
- Manually collect more than five healing potions in each session type, use one, and verify
  exactly one instance is removed. Check empty inventory and full-health behavior.
- Verify goods remain session-only and existing equipment replacement rules are unchanged.

**Done when:** procedural pickups use their own catalog resources, and either potion
variant works without an ID-specific check or quantity limit.

## Phase 5 - Display a Goods Bag

1. Replace the potion, lighter, and ender-eye rows and labels in the character sheet scene
   with one goods bag. Render every distinct good as its own atlas icon and quantity,
   counting instances in `Inventory.goods` without item-ID-based filtering or grouping.
2. Group by `GoodResource` instance and reuse the catalog/scene resource for each pickup
   of the same good; do not merge different goods merely because their icons match. If
   resources are duplicated dynamically in the future, define a stable non-ID grouping
   key before relying on such duplicates to appear as one entry.
3. Rebuild the bag on refresh without leaving duplicate controls. Preserve weapon, armor,
   companion, and other character sheet behavior; handle empty goods and null icons.

### Validation

- Manually inspect classic and RPG sessions separately. Check an empty bag, one and several
  instances of a good, different goods, quantities above five, and quantity changes after
  potion use. Confirm each entry displays the correct session-specific atlas icon.
- Refresh and reopen the sheet repeatedly, check the bag stays readable as it grows, and
  verify equipment and companions still display correctly.

**Done when:** the character sheet displays goods and their quantities without knowing
their IDs, and both session types display their own item artwork.