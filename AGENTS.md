# AGENTS.md — Project Code Review & Refactoring Suggestions

## Project Overview

A Godot 4 visual novel / adventure game (PROJECT_MITA). Uses a tile-based top-down view with NPC interactions, dialogue via DialogueManager plugin, an inventory/quest system, a pause menu (phone UI), and a samples puzzle minigame.

---

## Structure

```
addons/          — Godot addons (DialogueManager, etc.)
audio/           — Sound files
dialogues/       — Dialogue resources (conventions: dialogues/AGENTS.md)
fonts/           — Font assets
images/          — Sprites and textures
lang/            — Translations
materials/       — Shader materials
scenes/          — .tscn scenes (gameplay locations, NPCs, UI)
scripts/         — All GDScript source
   *.gd          — Shared registries (Enums, Flags) plus gameplay scripts tied
                   to a specific scene or object (player, interaction controller,
                   scene roots, puzzle, individual zones)
   autoloads/    — Singletons: GameManager, SaveSystem, Quests, Inventory,
                   DialogueGlobals, SoundManager, plus PlayerSpawnScene
                   (base class for location roots that spawn the player)
   system/       — Reusable building blocks for scenes: interaction
                   (Interactable and its ZoneEvent/ObjectEvent subclasses),
                   Npc marker, Y-sort helper
   constants/    — Registries of ids and paths: ItemIds, QuestIds,
                   InputActions, ScenePaths
   resources/    — Custom Resource classes (EventAction and its subtypes,
                   Item, Quest)
   ui/           — HUD, pause/options menus, dialogue balloon (UI в
                   DialogueBalloon, поток в DialogueController, переменные
                   диалога в DialogueContext), portraits
   1_mom_home/   — Scene-specific cutscene scripts, chapter 1
   2_mike_room/  — Scene-specific cutscene scripts, chapter 2
   experimental/ — Unfinished experiments; leave untouched
shaders/         — GLSL shaders
```

## Conventions worth knowing

- Flag names come from `scripts/flags.gd` (`Flags.*`); never use string literals.
- Gameplay locations are `.tscn` roots extending `PlayerSpawnScene`, so the player
  is restored from `GameManager.player` instead of being re-instantiated.
- Scene transitions go through `GameManager.start_scene_transition()`: it queues
  the target scene, keeps the player state (facing, flashlight) and fades out.
- Interactive scene nodes extend `Interactable` (`scripts/system/`) and override
  `_can_interact()` / `_on_interact()`; the template methods `can_interact()` /
  `on_interact()` stay in the base class.
- Saves are plain dictionaries written by `SaveSystem` with `SAVE_VERSION`. Only
  `Resource` objects may be stored as-is; other classes (inventory stacks) must be
  converted to plain data first (`Inventory.to_dict()` / `Inventory.from_dict()`).
