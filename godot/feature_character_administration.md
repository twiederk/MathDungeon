# Feature: Character Administration

## Goal

Introduce the concept of a **gamer** (the end user) and a **character** (an RPG-style avatar the
gamer plays). A character has a name, a portrait, an inventory and companions. Damage and armor are
derived from the inventory and companions. Before the game starts, the gamer chooses between the
characters they have created. Characters are displayed with name, portrait, hit points, max hit
points, damage, armor, inventory and companions.

## Decisions

| Topic | Decision |
|---|---|
| Character authoring | The gamer creates characters (name + portrait chosen from a catalog) |
| Save slots | One save file per character: `user://characters/<id>.save` |
| Damage/armor rule | Best item wins (preserves current behaviour) |
| Inventory persistence | Persistent — items carry over between runs |
| Portraits | Fixed catalog of images shipped in `res://` |
| Backwards compatibility | Old saves may break; no v1 migration needed |
| Death handling | No permadeath. The save is not written while `hit_points == 0`, so the stored character always stays alive and keeps its inventory (current behaviour) |

### Consequence: characters are save data, not resources

Because the gamer creates them, characters cannot be `res://*.tres` files — those are read-only
after export. And because the inventory is persistent, **the character *is* the save file**.

Portraits still come from a fixed catalog: the character stores a `portrait_id: String`, and a
`PortraitCatalog` maps that id to a `res://` texture. A texture path is never serialized into the
save file.

## Current state

- `PlayerStats` (autoload) mixes persistent character identity (`weapon_damage`, `armor`,
  `companion_paths`) with per-run state (`score`, `hit_points`, `eyes_of_ender`, `has_lighter`).
- Items are fire-and-forget: `Sword` and `Helmet` write `max(current, new)` into an int and
  `queue_free()`. There is no record of *which* item was picked up.
- Companions are stored as **scene tree node paths**. These resolve in `main.tscn` because it has a
  static `$Companions` node, but `ProcGenWorld` has no such node — so `Main._setup_companions()`
  silently finds nothing and `get_total_damage()` returns wrong values there.
- `SaveManager` writes one global JSON blob containing three ints plus the node paths.

## Phases

Each phase is independently shippable.

### ✓ Phase 1 — `Character` data object

Create `characters/character.gd` as `class_name Character extends RefCounted`:

```gdscript
var id: String            # generated once, used as the filename
var display_name: String
var portrait_id: String
var max_hit_points: int = 5
var weapon_damage: int = 1
var armor: int = 0
var companions: Array[String] = []
```

Add a `CharacterManager` autoload holding `current: Character`.

Reduce `PlayerStats` to run state only (`hit_points`, `score`, `eyes_of_ender`) and delegate
`max_hit_points` to `CharacterManager.current`.

**Critical:** expose the *API* now, even though the implementation is trivial:

```gdscript
func get_damage() -> int:
	return weapon_damage

func get_armor() -> int:
	return armor

func has_item(item_id: String) -> bool:
	return item_id == "lighter" and _has_lighter
```

Every consumer (`quiz_dialog.gd`, `main.gd`, `StatsSheet`, `hurt()`) calls these from day one. Phase 9
then becomes a pure internal swap and no call site changes twice.

Update `test/test_PlayerStats.gd`.

### ✓ Phase 2 — Per-character persistence

`user://characters/<id>.save`:

```json
{
  "version": 2,
  "id": "…",
  "display_name": "…",
  "portrait_id": "steve",
  "max_hit_points": 5,
  "hit_points": 4,
  "weapon_damage": 2,
  "armor": 1,
  "companions": []
}
```

`SaveManager` gains `list_characters()`, `load_character(id)`, `save_character(character)` and
`delete_character(id)`.

Keep `companions` as a plain `Array[String]` carrying today's node paths — do not clean it up yet.
Phase 7 changes what the strings *mean*, not the schema.

The `if hit_points > 0` guard stays: the character file is never written while dead.

**Security:** on load, validate every id against the catalog/databases and silently drop unknown
entries. A hand-edited save must never crash the game or cause an arbitrary resource path to load.
The generated `id` is the filename — never the gamer-supplied name.

### Phase 3 — Portrait catalog

Create `characters/portrait_catalog.tres`: an array of `{ id, display_name, texture }`. Put the
images in `res://characters/portraits/`. Lookup is strictly id-based.

### Phase 4 — `CharacterWidget` renders a character

Replace the global `PlayerStats` read in `gui/character_widget.gd` with `setup(character: Character)`.
Replace the placeholder `CanvasTexture` in `character_widget.tscn` with a real `TextureRect` bound to
the portrait, plus a `Label` for the name.

Leave an empty `HBoxContainer` named `InventoryStrip` in the scene so Phase 9 is purely additive.

**First visible result: the character has a face and a name.**

### Phase 5 — Character creation dialog

`gui/character_create.tscn`: a name `LineEdit` plus a portrait picker driven by the catalog.

Sanitize the name: trim whitespace, limit length (~16 characters), reject empty.

Persistence landing in Phase 2 means the first version of this dialog already produces a character
that survives a restart.

**The gamer can now set a name and a portrait.**

### Phase 6 — Character selection screen

`gui/character_select.tscn`: a grid of `CharacterWidget`s built from `SaveManager.list_characters()`,
plus a "new character" tile and a delete button with confirmation.

Selecting a character sets `CharacterManager.current` and starts the game.

Rewire `gui/start_menu.gd`: "Start" leads to the selection screen. The separate "Load" button
disappears — selecting a character *is* loading.

**Shippable milestone: the gamer creates, picks and plays named characters with portraits.**

### Phase 7 — Companions by id

Create `companions/companion_definition.gd` (`Resource`: `id`, `display_name`, `icon`,
`scene: PackedScene`, `damage`) and a `CompanionDatabase` autoload.

`Wolf.execute()` stores the **id** instead of `str(get_path())`.

Rewrite `Main._setup_companions()` to **instantiate** `definition.scene` into `companions_root`
rather than looking up node paths.

Add a `Companions` node to `proc_gen_world.tscn` so procedural worlds behave identically.

This phase is the pilot for the "definition + database" pattern reused in Phase 8.

### Phase 8 — Item definitions

Create `items/item_definition.gd` (`Resource`: `id`, `display_name`, `icon`, `slot`, `damage`,
`armor`) and `.tres` files for the five existing items. Add an `ItemDatabase` autoload mapping
`id -> ItemDefinition`.

Add `@export var definition: ItemDefinition` to the item scenes.

These *are* `res://` resources — item **types** are authored by the developer. Only item
**ownership** is save data.

### Phase 9 — Inventory replaces the ints

Add `inventory: Array[String]` to `Character` and make the getters derive from it:

```gdscript
func get_damage() -> int:
	var best := base_damage
	for id in inventory:
		var item := ItemDatabase.get_item(id)
		if item and item.slot == ItemDefinition.Slot.WEAPON:
			best = max(best, item.damage)
	for id in companions:
		best += CompanionDatabase.get_companion(id).damage
	return best
```

`Sword.execute()` / `Helmet.execute()` become `CharacterManager.current.add_item(definition.id)`.
`has_lighter` becomes `has_item("lighter")`.

**Saving must become explicit.** Today it is a side effect of the `weapon_damage` / `armor` setters.
Once those are derived getters that trigger disappears:

```gdscript
func add_item(item_id: String) -> void:
	if item_id in inventory:
		return
	inventory.append(item_id)
	inventory_changed.emit()
	_save_if_alive()


func _save_if_alive() -> void:
	if PlayerStats.hit_points > 0:
		SaveManager.save_character(self)
```

Keep `weapon_damage_changed` / `armor_changed` as forwarders of `inventory_changed` so `main.gd`
stays untouched.

Bump the save format: replace `weapon_damage` / `armor` with `inventory`.

Fill the `InventoryStrip` in `CharacterWidget` with icons from `ItemDefinition.icon`.

### Phase 10 — Polish

- Per-character base stats and starting equipment for real variety.
- Highscores keyed by character.
- Decide whether a wounded character heals on selection (see below).

## Open points

- **Parked hit points.** A character keeps its last-saved-alive HP, so it can appear in the selection
  screen at 2/5. If that reads as confusing, a "heal on select" rule is a one-line addition that does
  not touch the save format.

## Notes

- The save format is invalidated twice (Phase 2 and Phase 9). Do not hand a build to testers between
  Phase 6 and Phase 9 expecting their progress to survive.
- `CharacterWidget` is touched twice (Phase 4 and Phase 9). The pre-placed `InventoryStrip` keeps the
  second change additive.
