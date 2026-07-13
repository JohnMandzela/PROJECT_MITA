# AGENTS.md — Project Code Review & Refactoring Suggestions

## Project Overview

A Godot 4 visual novel / adventure game (PROJECT_MITA). Uses a tile-based top-down view with NPC interactions, dialogue via DialogueManager plugin, an inventory/quest system, a pause menu (phone UI), and a samples puzzle minigame.

---

## Structure

```
addons/          — Godot addons (DialogueManager, etc.)
audio/           — Sound files
dialogues/       — Dialogue resource files
fonts/           — Font assets
images/          — Sprites and textures
lang/            — Translations
materials/       — Shader materials
scenes/          — .tscn scene files (main_menu, mom_home, mike_room, offices, etc.)
scripts/         — All GDScript source
   autoloads/    — Singletons (GameManager, SaveSystem, Quests, Items, etc.)
   system/       — Base classes (Npc, Event, NextScene)
   ui/           — HUD overlays, menus, dialogue balloon, portraits
   1_mom_home/   — Scene-specific scripts for chapter 1
   2_mike_room/  — Scene-specific scripts for chapter 2
      furniture/ — Individual interactive furniture objects
shaders/         — GLSL shaders
```

---

## Review Summary

### Strengths

- Well-organized project structure separating scenes, scripts, and assets
- Clean use of autoload singletons for global state (GameManager, Items, Quests, SaveSystem)
- DialogueManager plugin integration is solid
- Samples puzzle is a substantial, well-architected minigame with clear turn-based logic
- Russian comments throughout provide good documentation
- Use of `@export` for inspector-driven configuration
- Deferred calls and async/await used appropriately for scene transitions

---

## Critical Issues

### 1. Massive Duplication of Interaction Pattern (HIGH PRIORITY)

The `Area2D` interaction zone pattern (`last_scene.gd`, `next_scene.gd`, `event.gd`, `dorm_area_event.gd`, `dialogue_reception.gd`, `offices_coffee_zone.gd`, `programming_office_puzzle_zone.gd`, and 8 furniture scripts) is copy-pasted ~15 times with minor variations. This violates DRY at an extreme level.

**Suggestion:** Extract a base class (e.g., `InteractionZone.gd`) with:
- `required_direction`, `label`, `player` tracking
- `_is_correct_direction()` (already duplicated identically 15+ times)
- `_on_body_entered/_on_body_exited`
- Virtual methods for `_on_interact()` and `_on_focused()`/`_on_unfocused()`
- Subclass for dialogue interactions, scene transitions, item pickups, etc.

### 2. `npc.gd` and `character_portrait.gd` Use Issues

- `npc.gd` (base class) has empty `_ready()` and `_process()` — useless boilerplate
- `engine_is_embedded_in_editor` window-centering code copy-pasted into 8+ furniture scripts — should be a utility or done once
- `dialogue_globals.gd` has a `TODO: сделать по-человечески` and placeholder data for mom

### 3. Inconsistent `@export_enum` Usage

In `last_scene.gd` and `next_scene.gd`:
```gdscript
@export_enum("up", "down", "left", "right")
var exit_direction: String
```
This creates an unused `@export_enum` decorator because it's applied to nothing (it needs to be on the next line). The decorator is floating and has no effect. Should be:
```gdscript
@export_enum("up", "down", "left", "right")
var exit_direction: String
```
— actually that IS how it looks, but the `@export_enum` must be directly above the variable it decorates. The issue is there's a comment between them or a blank line. Let me re-check: In `last_scene.gd` line 9 the `@export_enum` has no attached variable — it's followed by a comment line, then `var exit_direction`. So the decorator does nothing. Same in `next_scene.gd`.

## Medium Issues

### 4. Hardcoded Strings for Directions

`_is_correct_direction()` uses string literals `"up"`, `"down"`, `"left"`, `"right"` — compared against `player.last_direction`. The `Enums.Direction` values exist but are only used in the `match`, not to define the actual string values. The player's `last_direction` should be an enum, not a string.

### 5. Options Script Legacy Code

`scripts/ui/options.gd` has volume sliders whose `_on_sounds_value_changed` and `_on_music_value_changed` are completely empty (`pass`). Audio settings don't work from the options screen. Only the pause menu options work properly.

### 6. `last_scene.gd` vs `next_scene.gd` — Near-Identical Code

These two files are essentially the same script with a minor difference (`last_scene` lacks `entrance_animation()`). One should inherit from the other, or both from a base `SceneTransition` class.

### 7. Direct DialogueManager Singleton Access

Many scripts call `Engine.get_singleton("DialogueManager")` directly. This couples every interactive object to the plugin singleton. Better: create a thin wrapper autoload or use signals.

### 8. Inventory Grid and HUD Are Built in Code

`game_interface_overlay.gd` builds the entire HUD (panels, buttons, inventory grid, webcam, status bars) procedurally in `_build_overlay()`. This is fragile and hard to iterate on — should be a `.tscn` scene with `@onready` references.

### 9. Quest System Re-Syncs on Every Frame

`quest_system.gd` calls `sync_quest_progress()` on every `set_done`/`reload` which iterates all quests and flags. This is fine for small data but could become a perf issue.

### 10. `save_system.gd` — Assert on User Data

Line 149: `assert(_save_data != null, "Нет данных для загрузки")` — assert crashes the game. Should be a proper error return.

## Minor Issues

### 11. Debug Variables Leaked Into Production

`samples_puzzle.gd` has ~12 debug variables (`debug_forced_spawn_rolls`, `debug_disable_random_walls`, etc.) mixed with game state. Should be behind `OS.is_debug_build()` checks or in a separate debug script.

### 12. `pass` Boilerplate

- `emily_npc.gd`, `mom_npc.gd`, `mike_npc.gd` are all 1-line files just `extends Npc`. If they add nothing, remove them and use the base class directly in scenes.
- `npc.gd` has empty `_ready()` and `_process(pass)` — unnecessary.

### 13. Magic Numbers

- `await get_tree().create_timer(0.7).timeout` appears in 4+ places for door animation
- `0.1` appears as dialogue cooldown in 8+ places
- Screen coordinates hardcoded in `offices.gd` (`Rect2(68.0, 78.0, 862.0, 478.0)`)
- Should be named constants

### 14. `washmashine.gd` (typo — should be `washing_machine`)

### 15. `set.gd` — Unused Utility

The `Set` class (`class_name Set`) exists but is never referenced anywhere in the codebase.

### 16. Language: Mixed Russian/English Comments

All comments and UI strings are in Russian, which is fine for this team, but string constants ("up"/"down"/"left"/"right") and code are in English. Consider full localization.

### 17. `Input.set_mouse_mode` Called in Multiple Places

Mouse mode is set in `PlayerSpawnScene._ready()`, `close_pause_menu()`, `_apply_mouse_cursor_mode()`, `_enter_dialogue_mouse_mode()`, etc. Can conflict. A single source of truth would be better.

### 18. `minigame_pause_target` Pattern

`GameManager.minigame_pause_target` is set and checked across multiple scripts. This is a fragile coupling — consider using groups or signals instead.

---

## Refactoring Priority List

1. **Extract `InteractionZone` base class** — eliminates ~15 near-duplicate scripts
2. **Merge `last_scene.gd` / `next_scene.gd`** into one base with optional entrance animation
3. **Fix `@export_enum`** in scene transition scripts
4. **Fix `options.gd`** — implement volume slider handlers
5. **Replace direction strings with `Enums.Direction`** in player
6. **Move HUD construction from code to scene** — `game_interface_overlay.tscn`
7. **Remove unused `set.gd`** or integrate it
8. **Guard debug variables** in samples_puzzle behind debug checks
9. **Extract magic numbers** (timings, zone sizes, positions) into constants
10. **Replace `assert` in save_system** with safe error handling
