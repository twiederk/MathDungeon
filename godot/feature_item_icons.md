# Feature: Weapon/Armor Icons in CharacterSheetGui

## Goal
Show the weapon and armor icon (not just the name) in `CharacterSheetGui`, next to the
existing `WeaponLabel` / `ArmorLabel` text.

## Constraints / decisions
- The icon source data (texture, atlas frame, hframes/vframes) currently lives only in the
  pickup scenes (`sword_wood.tscn`, `sword_stone.tscn`, `sword_iron.tscn`,
  `helmet_wood.tscn`, `helmet_stone.tscn`, `helmet_iron.tscn`) as `Sprite2D` properties.
  Those scenes must keep their `Sprite2D` setup unchanged (so they still render correctly
  in the world/editor).
- The same icon info will be **duplicated** onto `WeaponResource` / `ArmorResource` as new
  `@export` fields, since that's the data already carried through `Inventory` /
  `Character` and the only data available to `CharacterSheetGui`. These new fields must be
  set manually in each `.tres` file to match the corresponding scene's `Sprite2D`
  (`texture`, `hframes`, `vframes`, `frame`).
- When no weapon/armor is equipped yet (`weapon_resource`/`armor_resource == null`), the
  `TextureRect` is hidden (`visible = false`).
- Icons are placed to the left of the existing label, on the same row.

## Changes

### 1. `items/weapon_resource.gd` / `items/armor_resource.gd`
Add icon fields and a helper to build the displayable texture:

```gdscript
@export var icon_texture: Texture2D
@export var icon_hframes: int = 16
@export var icon_vframes: int = 16
@export var icon_frame: int = 0

func get_icon() -> Texture2D:
    if icon_texture == null:
        return null
    var atlas := AtlasTexture.new()
    atlas.atlas = icon_texture
    var cell := icon_texture.get_size() / Vector2(icon_hframes, icon_vframes)
    var col := icon_frame % icon_hframes
    var row := icon_frame / icon_hframes
    atlas.region = Rect2(col * cell.x, row * cell.y, cell.x, cell.y)
    return atlas
```

(Identical helper in both resources; no shared base class exists today so it's duplicated
to match the existing pattern of these two classes.)

### 2. Resource `.tres` files
Set `icon_texture = items.png`, `icon_hframes = 16`, `icon_vframes = 16`, and `icon_frame`
to match each scene's `Sprite2D.frame`:

| Resource | frame |
|---|---|
| `sword_wood.tres` | 64 |
| `sword_stone.tres` | 65 |
| `sword_iron.tres` | 66 |
| `helmet_wood.tres` | 0 |
| `helmet_stone.tres` | 1 |
| `helmet_iron.tres` | 2 |

### 3. No item equipped
No placeholder icon is needed. When `weapon_resource`/`armor_resource` is `null`, the
corresponding `TextureRect` is simply hidden (`visible = false`).

### 4. `gui/character_sheet_gui.tscn`
Wrap `WeaponLabel` and `ArmorLabel` each in an `HBoxContainer` with a new `TextureRect`
before the label:

```
VBoxContainer
  ...
  HBoxContainer (new, "WeaponRow")
    TextureRect (new, "WeaponIcon")   custom_minimum_size = Vector2(20, 20), expand_mode/stretch_mode = keep-aspect
    Label ("WeaponLabel", moved in)
  HBoxContainer (new, "ArmorRow")
    TextureRect (new, "ArmorIcon")
    Label ("ArmorLabel", moved in)
  ...
```

### 5. `gui/character_sheet_gui.gd`
- Add `@onready var weapon_icon: TextureRect = $.../WeaponRow/WeaponIcon`
- Add `@onready var armor_icon: TextureRect = $.../ArmorRow/ArmorIcon`
- In `_refresh()`, after setting `weapon_label.text` / `armor_label.text`, set:
  ```gdscript
  weapon_icon.visible = inventory.weapon_resource != null
  weapon_icon.texture = inventory.weapon_resource.get_icon() if weapon_icon.visible else null
  armor_icon.visible = inventory.armor_resource != null
  armor_icon.texture = inventory.armor_resource.get_icon() if armor_icon.visible else null
  ```
  (Note: repo style forbids single-line ternary `if` expressions in general code, so this
  will be written as plain `if`/`else` blocks when implemented, not as shown above.)

## Testing
- Add/extend GUT tests under `test/` for `WeaponResource.get_icon()` /
  `ArmorResource.get_icon()` verifying the returned `AtlasTexture.region` matches the
  configured frame/hframes/vframes.
- Manual check in editor: open `character_sheet_gui.tscn`, run game, equip wood sword and
  wood helmet, confirm icons show the correct sprite and match the in-world pickup icon.


