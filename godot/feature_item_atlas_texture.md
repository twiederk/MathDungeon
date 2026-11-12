# Feature: Item Atlas Textures

## Goal

Replace item sprite-sheet frame selection with `AtlasTexture` regions in `res://items`,
`Item`, `WeaponResource`, `ArmorResource`, `GoodResource`, and `CharacterSheetGui`.
Introduce and populate atlas textures before removing the legacy resource fields.
Keep every implementation phase independently usable.

## Current Constraints

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
   character loads the same equipment and goods by ID, and exercise pickups and the character
   sheet in game.

**Done when:** no item resource depends on a frame number or constructs an icon atlas at
runtime, the character sheet uses the stored atlas directly, and gameplay and saved
inventories retain their existing behavior.