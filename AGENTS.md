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
   autoloads/    — Singletons (GameManager, SaveSystem, Quests, Inventory, etc.)
   system/       — Base classes (Npc, Event, NextScene)
   ui/           — HUD overlays, menus, dialogue balloon, portraits
   1_mom_home/   — Scene-specific scripts for chapter 1
   2_mike_room/  — Scene-specific scripts for chapter 2
      furniture/ — Individual interactive furniture objects
shaders/         — GLSL shaders
```
