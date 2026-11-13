# RPG Starting Character

## Goal

Starting a new procedural game creates and activates a fresh RPG character with the RPG wooden sword, no armor, and no goods. Starting a classic game and switching or creating ordinary characters keep their existing behavior.

## Current Behavior

- `gui/start_menu.gd` has separate classic and procedural start buttons. Both reset the session and start a world using the currently selected saved character.
- `CharacterManager` creates and loads the classic default character with ID `000`. Other characters are saved individually by `SaveManager`.
- The RPG wooden sword is `res://procedural/items/sword_wood.tres`, with item ID `rpg_sword_wood`; it is already registered in the item catalog.
- Weapons, armor, base stats, and companions are saved with a character. Goods are session-only and are not serialized.

## Proposed Behavior

- Treat the procedural start button as a new game: every press starts a fresh RPG character, even if a previous RPG run acquired equipment or companions. World transitions within that run must not reset the character.
- Reserve a descriptive, nonnumeric ID such as `rpg_default` for this character. Keep the existing `000` classic default and numeric IDs for user-created characters unchanged.
- Give the RPG character the existing default name and portrait unless a separate RPG identity is specified later. Use fresh `Character` defaults for health and base stats, an empty companion list, and a new inventory containing only the RPG wooden sword.
- Replace only the reserved RPG character's save at the start of a new procedural game; never overwrite the selected ordinary character or its save. Existing saves remain usable without migration.
- The normal character-switching flow may list the reserved character, consistent with the existing save listing. Starting a procedural game still resets it; starting a classic game continues to use the selected character.

## Implementation

1. Add a reserved RPG character ID and a preloaded RPG sword resource in `characters/character_manager.gd`. Provide a dedicated operation that constructs a new `Character`, sets its ID, name and portrait, equips the RPG sword, saves it, and assigns it to `CharacterManager.current`. Ensure character initialization cannot write a partially initialized record: inventory changes emit a save signal, so initialize identity before equipping and make the final save explicit.
2. Call that operation from `_on_start_generic_button_pressed()` in `gui/start_menu.gd` before entering the procedural world. Keep the existing session and achievement resets and timed-run setup. Do not call it from world initialization, portal transitions, menu initialization, or the classic start handler.
3. Keep the reserved ID outside the numeric IDs produced by `CharacterCreateDialog`, and verify generated IDs cannot collide with it. Do not alter the classic default character or change the persistence policy for goods.
4. Confirm the selected character and character widget remain coherent when returning to the start menu, and that saving/loading the RPG sword resolves through the existing catalog.

## Verification

- Add focused GUT tests that start with an upgraded reserved RPG character and a different selected saved character, then verify a new procedural run activates the reserved ID with `rpg_sword_wood`, no armor, no goods, fresh health/base stats, and no companions.
- Verify repeated procedural starts reset the reserved character, while leaving the other character's saved equipment and stats unchanged.
- Verify saving and loading the reserved character resolves the RPG sword and does not persist goods; avoid overwriting real saves in tests by isolating or restoring test data.
- Verify classic starts still use the selected character, numeric character creation does not produce the reserved ID, and scene/portal transitions do not reset the current RPG character.
- Run the focused character, save-manager, and start-menu tests, then the project's GUT suite.