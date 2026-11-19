# AGENTS.md — Project Code Review & Refactoring Suggestions

## Project Overview

A Godot 4 visual novel / adventure game (PROJECT_MITA). Uses a tile-based top-down view with NPC interactions, dialogue via DialogueManager plugin, an inventory/quest system, a pause menu (phone UI), and a samples puzzle minigame.

---

## Structure

```
addons/          — Godot addons (DialogueManager, etc.)
assets/          — Runtime assets
   audio/        — Music, sounds, default_bus_layout.tres
   fonts/        — Font assets
   images/       — Sprites and textures (characters, items, phone, scenes,
                   tilesets, ui, editor)
   lang/         — Translations source (chars.csv) and compiled translation
   materials/    — Shader materials
   shaders/      — GLSL shaders
content/         — Game content data
   dialogues/    — Dialogue resources (conventions: content/dialogues/AGENTS.md)
   items/        — Item resources
   quests/       — Quest resources
scenes/          — .tscn scenes
   locations/    — Playable locations (mom_home, dorm, mihyung_offices)
   characters/   — Player and NPC scenes
   ui/           — Menus, balloon, HUD
   experimental/ — Unfinished experiments; leave untouched
scripts/         — All GDScript source
   *.gd          — Shared registries (Enums, Flags) plus gameplay scripts tied
                   to a specific scene or object (player, interaction controller,
                   scene roots, puzzle, individual zones)
   autoloads/    — Singletons: GameManager, SaveSystem, Quests, Inventory,
                   ItemNotifications, DialogueGlobals, SoundManager
   system/       — Reusable building blocks for scenes: interaction
                   (Interactable and its ZoneEvent/ObjectEvent subclasses),
                   Npc marker, Y-sort helper, PlayerSpawnScene base class
   constants/    — Registries of ids, paths and resources: ItemIds, QuestIds,
                   InputActions, ScenePaths, Sounds
   resources/    — Custom Resource classes (EventAction and its subtypes,
                   Item, Quest)
   ui/           — HUD, pause/options menus, dialogue balloon (UI в
                   DialogueBalloon, поток в DialogueController, переменные
                   диалога в DialogueContext), portraits, item toast
   scenes/       — Location-specific scripts (mom_home, mike_room)
   experimental/ — Unfinished experiments; leave untouched
tests/           — GUT tests
```

## Naming

- Only `lower_snake_case` for files and folders: no spaces, Cyrillic, apostrophes,
  `$`, dashes or camelCase (`programming_office.tscn`, `moms_home.png`).
- Files are grouped by role: runtime assets under `assets/`, data resources under
  `content/`, scenes under `scenes/<kind>/`, code under `scripts/<kind>/`.
- Every moved or renamed file keeps its `.import`/`.uid` sidecar; references are
  by `uid://`, so update both the file and the sidecar together.

## Conventions worth knowing

- Flag names come from `scripts/flags.gd` (`Flags.*`); never use string literals.
- Gameplay locations are `.tscn` roots extending `PlayerSpawnScene`, so the player
  is restored from `GameManager.player` instead of being re-instantiated.
- Scene transitions go through `GameManager.start_scene_transition()`: it queues
  the target scene, keeps the player state (facing, flashlight) and fades out.
- Interactive scene nodes extend `Interactable` (`scripts/system/`) and override
  `_can_interact()` / `_on_interact()`; the template methods `can_interact()` /
  `on_interact()` stay in the base class.
- The player has a single scene (`scenes/characters/player.tscn`) with a
  `PhantomCamera2D` + `Camera2D` + `PhantomCameraHost`. Locations that need a fixed
  frame add their own `PhantomCamera2D` with a higher `priority`; no second
  `Camera2D` and no `player_with_camera` scene.
- Saves are plain dictionaries written by `SaveSystem` with `SAVE_VERSION`. Only
  `Resource` objects may be stored as-is; other classes (inventory stacks) must be
  converted to plain data first (`Inventory.to_dict()` / `Inventory.from_dict()`).
- Cutscenes are `.dialogue` files with a `skip` title. Esc (`ui_cancel`) fast-forwards
  the current dialogue through `DialogueController.skip_cutscene()`; while it runs,
  `GameManager.is_skipping_cutscene` is set and dialogue-facing functions (fades,
  waits, sounds, animations, `mom_move`, portraits) check it to skip animations and
  waiting. Details: `content/dialogues/AGENTS.md` §4.7.
- Pause menu never opens while a dialogue balloon is active (`dialogue_balloons` group).

## Debug variables

- Debug switches live in `DebugConfig` (`scripts/autoloads/debug_config.gd`), not in
  `GameManager`.
- Values come from `res://.env`, which is gitignored. Copy `.env.example` to `.env`
  and set keys such as `SKIP_INTRO=true`. The dotenv plugin (`DotEnv` autoload)
  loads the file at startup.
- Missing `.env` is fine: every switch falls back to its default. Release builds
  ignore `.env` entirely (`OS.is_debug_build()` check in `DebugConfig`).
- Adding a new debug switch: field + default in `DebugConfig`, read it via
  `_bool("KEY", default)` (or add a typed helper) and document the key in
  `.env.example`.
