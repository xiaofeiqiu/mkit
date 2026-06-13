# MKit — Godot 4 Modular RPG Framework Course

> Build a reusable Godot 4 framework for 2D RPG, roguelike, and action RPG games — then use the framework to create a playable demo.

This repository is designed as the source project for a practical Udemy course.

Most Godot tutorials teach how to build **one game**.  
This course takes a different approach:

1. Build a reusable game framework.
2. Use each framework system immediately in a real demo scene.
3. Finish with both a reusable kit and a playable 2D RPG / roguelike demo.

The goal is not only to finish a small game, but to learn how to structure Godot projects that can grow beyond a prototype.

---

## Course Title

**Godot 4 Modular RPG Framework: Build a Reusable 2D Roguelike Game Kit**

### Subtitle

Learn GDScript architecture by building a reusable command, state, action, effect, combat, quest, loot, and save system — then use it to create a playable RPG demo.

---

## What This Course Is About

This course teaches how to build a reusable Godot 4 game kit for 2D RPG and roguelike-style games.

Instead of placing all logic directly inside one player script or one scene tree, the project is organized around reusable runtime systems:

```text
Input / AI / Script
→ GameCommand / CommandReceiver
→ StateMachine / State
→ GameAction / ActionService
→ GameEffect / EffectService
→ Domain Service
→ EventService
→ UI / Audio / VFX
```

This pipeline is the core design of the course.

Students will learn how to separate:

```text
Reusable framework code
Game-specific content
Demo scenes
Data definitions
UI feedback
Tests
```

By the end of the course, students should understand how to build a Godot project that is easier to extend, test, and reuse.

---

## Target Students

This course is for developers who already know some Godot basics and want to build cleaner, larger, more reusable projects.

It is especially suitable for:

- Godot developers who know how to make small prototypes but struggle with architecture.
- Indie developers building 2D RPG, roguelike, action RPG, or survivor-like games.
- Programmers who want reusable gameplay systems instead of one-off scripts.
- Students who want more than a simple clone tutorial.
- Developers who want to learn practical GDScript architecture.

This course is not intended for absolute beginners who have never opened Godot before.

---

## Final Demo

The final course project is a small but complete playable demo.

### Demo Concept

```text
Crystal Village Demo
```

### Final Gameplay Loop

```text
Player starts in a small village.
Player talks to an elder NPC.
Player accepts a quest.
Player enters a field area.
Player fights enemies with melee and firebolt.
Enemies take damage, die, and drop rewards.
Quest progress updates through gameplay events.
Player enters a simple multi-room trial.
Each cleared room gives one reward choice.
Player can save and load progress.
```

### Expected Demo Features

- Player movement
- Melee attack
- Firebolt ability
- Enemy AI
- Health and damage
- Damage popup
- Hit VFX
- Basic sound feedback
- NPC dialogue
- Quest progress
- Loot reward
- Room clear loop
- Reward choice screen
- Save and load
- Basic automated tests

---

## Project Architecture

The course uses a three-layer architecture:

```text
Game Content
    ↓
MKit Modules
    ↓
Kernel Runtime
```

### 1. Game Content

Game-specific content lives outside the reusable addon.

Examples:

```text
Player scene
Enemy scenes
NPC dialogue
Quest data
Room layouts
Sprites
Animations
UI screens
Demo-specific scripts
```

Game content is allowed to depend on MKit, but MKit should not depend on the specific game.

---

### 2. MKit Modules

Modules are reusable gameplay systems built on top of the kernel.

Examples:

```text
Combat
Abilities
Loot
Quest
Dialogue
Progression
World
Save
```

Modules contain reusable gameplay logic, but they should avoid knowing about specific enemies, NPCs, maps, or demo scenes.

---

### 3. Kernel Runtime

The kernel contains the lowest-level reusable runtime systems.

Examples:

```text
ServiceRegistry
GameBootstrap
ModuleBootstrap
GameCommand
CommandReceiver
StateMachine
GameAction
GameEffect
EventService
ContentService
ResourceDatabase
SaveService
```

The kernel should stay small, stable, and generic.

---

## Recommended Folder Structure

```text
res://
├── addons/
│   └── mkit/
│       ├── kernel/
│       │   ├── bootstrap/
│       │   ├── services/
│       │   ├── command/
│       │   ├── state_machine/
│       │   ├── action/
│       │   ├── effect/
│       │   ├── event/
│       │   ├── content/
│       │   └── save/
│       │
│       └── modules/
│           ├── combat/
│           ├── ability/
│           ├── loot/
│           ├── quest/
│           ├── dialogue/
│           ├── progression/
│           └── world/
│
├── game/
│   ├── actors/
│   ├── enemies/
│   ├── npc/
│   ├── abilities/
│   ├── quests/
│   ├── rooms/
│   ├── ui/
│   ├── audio/
│   ├── vfx/
│   └── bootstrap.tscn
│
├── game_template/
│   └── starter_scene.tscn
│
├── test/
│   ├── unit/
│   └── integration/
│
└── docs/
    ├── cookbook/
    ├── architecture/
    └── reference/
```

---

## Key Rule

The addon is not the game.

```text
addons/mkit/ = reusable framework
game/        = specific game content
```

The game may depend on the addon.

The addon should not depend on the game.

This rule keeps the framework reusable across future projects.

---

## Core Gameplay Pipeline

A single attack flows through the system like this:

```text
Player presses Space
    ↓
Input creates GameCommand
    ↓
CommandReceiver receives command
    ↓
StateMachine checks current state
    ↓
Attack state starts GameAction
    ↓
GameAction handles timing
    ↓
GameEffect describes the world change
    ↓
EffectService applies the effect
    ↓
CombatService calculates damage
    ↓
EventService broadcasts result
    ↓
UI / Audio / VFX react
```

This pipeline is one of the most important concepts in the course.

It separates decision-making, timing, world changes, domain logic, and presentation feedback.

---

## Course Design Philosophy

Each section follows the same teaching rhythm:

```text
1. What You Will Build
2. High-Level Design
3. Core Concept
4. Implementation
5. Use It in the Demo Scene
6. Test, Debug, and Commit
```

The course avoids long theory-only sections.

Every major framework feature must produce a visible result in the demo.

For example:

```text
Build Command System
→ Use it to move the player

Build Action System
→ Use it to perform an attack

Build Effect System
→ Use it to damage an enemy

Build Event System
→ Use it to show damage popup and play sound

Build Quest System
→ Use it to track an NPC quest

Build Save System
→ Use it to save and load progress
```

---

## Course Scope

The full MKit framework can become very large.

The first Udemy course should focus on a smaller teaching edition that students can actually finish.

### Included in the First Course

```text
ServiceRegistry
GameBootstrap
ModuleBootstrap
Typed Mkit facade
ContentService
ResourceDatabase
EntityRoot
EntityContract
GameCommand
CommandReceiver
CommandService
StateMachine
State
GameAction
ActionService
GameEffect
EffectService
CombatService
AbilityController
AbilityDefinition
EventService
Health
Stats
Enemy AI
Loot
Quest
Simple Dialogue
Save / Load
GUT tests
```

### Not Included in the First Course

These systems can be saved for an advanced course or future expansion:

```text
Full inventory and equipment system
Full shop economy
Full procedural dungeon generator
Full platform layer
Ads
IAP
Cloud save
Complex editor plugin UI
Runtime module graph
Module manifest
Topological module assembly
Event DSL
Catalog compiler
Generic save migration framework
Full ECS replacement
```

This keeps the first course focused, achievable, and marketable.

---

## Course Curriculum

### Section 1 — Course Setup and Final Demo Preview

Goal:

```text
Understand what we are building and why the project is structured as a reusable kit.
```

Students will:

- Preview the final demo.
- Learn the difference between framework code and game content.
- Understand the three-layer architecture.
- Open the project and run the starter scene.

Demo progress:

```text
The student can run the project and see the final target.
```

---

### Section 2 — Runtime Kernel Foundation

Goal:

```text
Build the minimum runtime foundation.
```

Students will build:

```text
ServiceRegistry
GameBootstrap
ModuleBootstrap
Mkit typed facade
```

Demo progress:

```text
The game boots through a clean bootstrap scene.
Core services are registered and accessible.
```

---

### Section 3 — Entity, Command, and State Machine

Goal:

```text
Create the player entity and make movement command-driven.
```

Students will build:

```text
EntityRoot
EntityIdentity
EntityContract
GameCommand
CommandReceiver
StateMachine
IdleState
MoveState
PlayerInputController
```

Demo progress:

```text
The player can move with WASD.
Movement goes through GameCommand and StateMachine.
```

---

### Section 4 — Action and Effect Pipeline

Goal:

```text
Build the action/effect pipeline and use it for the first attack.
```

Students will build:

```text
GameAction
ActionService
GameEffect
EffectService
TimedAttackAction
DamageEffect
```

Demo progress:

```text
The player can perform a melee attack.
The attack triggers an effect instead of directly modifying the enemy.
```

---

### Section 5 — Combat System

Goal:

```text
Add reusable combat logic.
```

Students will build:

```text
HealthComponent
StatsComponent
DamageRequest
DamageResult
CombatService
Hit detection
Death event
```

Demo progress:

```text
Enemies can take damage and die.
Combat result events are broadcast to the rest of the game.
```

---

### Section 6 — Data-Driven Abilities

Goal:

```text
Move ability behavior into reusable definitions.
```

Students will build:

```text
AbilityDefinition
AbilityController
Cooldown
Firebolt ability
Projectile action
Ability cost and validation
```

Demo progress:

```text
The player can press Q to cast Firebolt.
Ability values come from resources instead of hardcoded scripts.
```

---

### Section 7 — Events, UI, Audio, and VFX

Goal:

```text
Connect gameplay events to presentation feedback.
```

Students will build:

```text
EventService
Damage popup
Hit VFX
Simple audio feedback
HUD health display
Ability cooldown UI
```

Demo progress:

```text
Combat feels responsive because UI, audio, and VFX react to events.
```

---

### Section 8 — Enemy AI and Loot

Goal:

```text
Add basic enemy behavior and reward drops.
```

Students will build:

```text
EnemyBrain
AI command sender
Chase behavior
Attack behavior
LootTable
LootService
Reward event
```

Demo progress:

```text
Enemies chase the player, attack, die, and drop loot.
```

---

### Section 9 — Quest and Dialogue

Goal:

```text
Add NPC interaction and quest progress.
```

Students will build:

```text
DialogueDefinition
DialogueService
QuestDefinition
QuestService
Quest objective
Quest progress event handling
```

Demo progress:

```text
The player talks to an NPC, accepts a quest, and progresses it through combat.
```

---

### Section 10 — Room Loop and Rewards

Goal:

```text
Build a small roguelike-style room loop.
```

Students will build:

```text
RoomDefinition
RoomController
Encounter spawn
Room clear condition
RewardChoice
Simple run director
```

Demo progress:

```text
The player clears multiple rooms and chooses rewards between rooms.
```

---

### Section 11 — Save, Load, and Testing

Goal:

```text
Make progress persistent and verify core systems with tests.
```

Students will build:

```text
SaveService
Save data model
Load flow
GUT unit tests
Integration smoke test
```

Demo progress:

```text
The player can save and load progress.
Core systems have basic automated test coverage.
```

---

### Section 12 — Packaging the Kit

Goal:

```text
Prepare the framework for reuse in future games.
```

Students will learn:

```text
How to keep addon code reusable
How to move MKit into a new Godot project
How to document public APIs
How to build a clean starter template
How to continue extending the framework
```

Demo progress:

```text
The student finishes with both a playable demo and a reusable game kit.
```

---

## Lesson 1 Detailed Plan

### Lesson Title

**From Messy Godot Projects to a Reusable RPG Framework**

### Suggested Duration

```text
12–15 minutes
```

### Lesson Goal

The first lesson should sell the idea of the course.

Students should understand:

```text
This is not only a game tutorial.
This is a framework-building course.
Every system we build will be used in a real demo.
```

---

### What Students Will Learn

By the end of Lesson 1, students will know:

```text
1. What the final demo will look like.
2. Why normal Godot projects often become messy.
3. The difference between game code and framework code.
4. The three-layer structure: game, modules, kernel.
5. Why ServiceRegistry is the only autoload.
6. How the rest of the course will be taught.
```

---

### Lesson 1 Recording Flow

#### 0:00–1:00 — Hook

Suggested script:

```text
Most Godot tutorials teach you how to build one game.

But after the course, your next project still starts from zero.

In this course, we will do something different.

We will build a reusable RPG and roguelike game kit.
And every time we add a system to the kit,
we will immediately use it in a playable game demo.
```

Show the final demo immediately:

```text
Player movement
Melee attack
Firebolt
Enemy damage
NPC dialogue
Quest update
Reward choice
Save and load
```

---

#### 1:00–3:00 — Show the Project Result

Show the main folders:

```text
addons/mkit/
game/
game_template/
test/
docs/
```

Explain:

```text
addons/mkit is the reusable framework.

game is the actual demo game.

game_template is a small starter project that can be reused.

test contains unit and integration tests.

docs contains architecture notes, cookbook examples, and reference material.
```

Key message:

```text
The addon is not the game.
The addon is the reusable engine layer we can move to future games.
```

---

#### 3:00–5:00 — High-Level Design

Show this diagram:

```text
Game Content
    ↓
MKit Modules
    ↓
Kernel Runtime
```

Explain each layer:

```text
Game Content:
Player, enemies, rooms, quests, NPC dialogue, UI, sprites, animations.

MKit Modules:
Combat, ability, quest, loot, dialogue, world, progression.

Kernel Runtime:
ServiceRegistry, command, state machine, action, effect, event, content, save.
```

---

#### 5:00–7:00 — Core Concept

Explain how one player attack flows through the framework:

```text
Player presses Space.

Input creates a GameCommand.

The CommandReceiver sends the command to the StateMachine.

The StateMachine checks whether the player can attack right now.

If yes, it starts a GameAction.

The action handles timing and animation windows.

The action creates a GameEffect.

The EffectService applies the effect.

The CombatService calculates the damage.

The EventService broadcasts the result.

UI, audio, and VFX react to the event.
```

Core teaching point:

```text
Input does not directly damage the enemy.

State does not directly update UI.

Combat does not directly play sound.

Each layer has one job.
```

---

#### 7:00–10:00 — Run the Demo

Show how to run the project:

```text
1. Open the project in Godot.
2. Confirm the MKit plugin is enabled.
3. Confirm ServiceRegistry is registered as the only autoload.
4. Run game/bootstrap.tscn.
5. Move with WASD.
6. Interact with E.
7. Attack with Space or J.
8. Cast Firebolt with Q.
```

The goal is not to explain every script yet.

The goal is to show students what they will rebuild step by step.

---

#### 10:00–12:00 — Explain the Teaching Version

Tell students:

```text
The full demo proves the kit works.

But we will not copy the full demo blindly.

We will rebuild a smaller teaching version step by step.

Each section adds one reusable system.

Then we immediately use that system in the game.
```

Explain the two visual stages:

```text
Debug Starter Version:
Uses simple shapes and debug labels.
Good for understanding architecture.

Course Visual Version:
Uses real sprites, animation, VFX, sound, and UI.
Good for the final demo and Udemy presentation.
```

---

#### 12:00–15:00 — Lesson 1 Assignment

Student task:

```text
1. Open the project.
2. Run the demo.
3. Find these folders:
   - addons/mkit/kernel
   - addons/mkit/modules
   - game
4. Write down one example of code that belongs in the addon.
5. Write down one example of content that belongs in the game.
6. Commit the initial project state.
```

Suggested commit:

```bash
git add .
git commit -m "course: inspect initial mkit project structure"
```

---

## Suggested First Five Lessons

These lessons should be recorded first as the course MVP.

The goal is to validate the teaching style before recording the entire course.

---

### Lesson 1 — From Messy Godot Projects to a Reusable RPG Framework

Goal:

```text
Show the final demo and explain the architecture.
```

Visible result:

```text
Student can run the demo and understand the folder structure.
```

---

### Lesson 2 — Bootstrap the Runtime with ServiceRegistry

Goal:

```text
Build the minimum runtime foundation.
```

Implement:

```text
ServiceRegistry
GameBootstrap
ModuleBootstrap
Mkit facade
```

Visible result:

```text
The game boots cleanly.
Registered service IDs are printed.
```

---

### Lesson 3 — Create the Player Entity Contract

Goal:

```text
Create a reusable player entity structure.
```

Implement:

```text
EntityRoot
EntityIdentity
Components
Controllers
Presentation
EntityContract
```

Visible result:

```text
Player appears in the scene.
Debug label shows player entity_id.
```

---

### Lesson 4 — Move the Player with Command and StateMachine

Goal:

```text
Make player movement command-driven.
```

Implement:

```text
GameCommand
CommandReceiver
StateMachine
IdleState
MoveState
PlayerInputController
```

Visible result:

```text
WASD moves the player.
Movement flows through command and state machine.
```

---

### Lesson 5 — Add the First Attack Action

Goal:

```text
Use action and effect systems to perform an attack.
```

Implement:

```text
AttackCommand
TimedAttackAction
GameEffect
EffectService
HealthComponent
```

Visible result:

```text
Player attacks.
Enemy HP decreases.
A combat event is printed or displayed.
```

This lesson should be considered for a free preview because it produces a clear gameplay result.

---

## Udemy Landing Page Draft

### Course Hook

```text
Stop rebuilding your Godot RPG systems from scratch.

In this course, you will build a reusable Godot 4 game kit for 2D RPG,
roguelike, and action RPG projects.

We will not only write framework code.

After every major system, we will immediately use it in a real playable demo.
```

---

### What You Will Learn

Students will learn how to:

```text
Build a reusable Godot 4 addon architecture
Separate framework code from game-specific content
Use ServiceRegistry and typed service access
Create a command-driven player controller
Build a state-machine-based entity system
Design Action and Effect pipelines
Implement health, stats, combat, abilities, and loot
Use resource definitions for data-driven gameplay
Connect gameplay events to UI, audio, and VFX
Add quests, dialogue, rewards, and save/load
Write basic unit and integration tests with GUT
Package a reusable kit for future Godot projects
```

---

### Who This Course Is For

```text
Godot developers who know the basics but struggle with project structure
Programmers who want reusable RPG and roguelike systems
Indie developers building 2D action RPG, roguelike, or survivor-like games
Students who want more than a simple clone tutorial
```

---

### Who This Course Is Not For

```text
Absolute beginners who have never opened Godot
People looking for a no-code RPG Maker-style tool
People who only want art, level design, or game design theory
```

---

## Recording Strategy

Do not record the full 10-hour course immediately.

Start with a Udemy MVP:

```text
Section 1: Setup and final demo preview
Section 2: Bootstrap and ServiceRegistry
Section 3: Player movement with Command and StateMachine
Section 4: Attack and Combat
Section 5: Firebolt ability, enemy death, and event feedback
```

This should produce roughly 2–3 hours of course content.

After recording this MVP, review:

```text
Is the project easy to follow?
Does each lesson produce visible progress?
Is the architecture clear?
Does the demo look good enough for Udemy?
Are the explanations too abstract?
Are students getting a real game result frequently enough?
```

Then continue with:

```text
Quest
Dialogue
Loot
Room loop
Reward choice
Save/load
Testing
Packaging
```

---

## Visual Quality Requirement

A framework course still needs a good-looking demo.

For teaching, simple debug shapes are useful.

For selling, the final demo should use:

```text
Real character sprite
Enemy sprite
Walking animation
Attack animation
Firebolt VFX
Hit flash
Damage popup
Simple tilemap
NPC portrait or dialogue box
Reward choice UI
Basic sound effects
```

The course should not look like only colored rectangles.

A good rule:

```text
Use simple visuals when explaining architecture.
Use polished visuals when showing final gameplay.
```

---

## Development Rules

### Rule 1 — Keep Framework and Game Separate

```text
Framework code goes into addons/mkit.
Game-specific content goes into game.
```

Do not hardcode demo enemies, quests, rooms, or NPCs inside the addon.

---

### Rule 2 — Use Services for Shared Runtime Systems

Good service examples:

```text
ContentService
CommandService
ActionService
EffectService
EventService
CombatService
QuestService
SaveService
```

Services should be registered during bootstrap.

Game code should access services through a typed facade when possible.

---

### Rule 3 — Commands Describe Intent

A command should describe what an entity wants to do.

Examples:

```text
move
stop_move
attack
cast_ability
interact
```

Input, AI, and scripts can all send commands.

This makes the same gameplay system usable by both the player and enemies.

---

### Rule 4 — State Controls What Is Allowed

A state decides what an entity can do right now.

Examples:

```text
Idle
Move
Attack
Cast
HitStun
Dead
```

For example:

```text
The player can attack from Idle.
The player can move from Idle.
The player cannot move while Dead.
The player may not cast during HitStun.
```

---

### Rule 5 — Actions Own Timing

An action controls timing.

Examples:

```text
Attack windup
Hit frame
Recovery
Projectile spawn delay
Cooldown start
```

Actions are useful when gameplay should not happen instantly.

---

### Rule 6 — Effects Describe World Changes

An effect describes a world change.

Examples:

```text
Apply damage
Heal target
Spawn projectile
Give item
Start quest
Complete quest
Play VFX
```

Effects should be reusable and testable.

---

### Rule 7 — Events Notify Other Systems

Events should announce what happened.

Examples:

```text
damage_applied
enemy_died
quest_started
quest_progressed
loot_dropped
room_cleared
save_completed
```

UI, audio, and VFX should react to events instead of being directly called from combat logic.

---

## Example System Flow

### Melee Attack

```text
Input
→ GameCommand("attack")
→ Player CommandReceiver
→ StateMachine enters AttackState
→ AttackState starts TimedAttackAction
→ TimedAttackAction waits for hit frame
→ DamageEffect is created
→ EffectService applies DamageEffect
→ CombatService calculates damage
→ HealthComponent loses HP
→ EventService emits damage_applied
→ UI shows damage popup
→ Audio plays hit sound
→ VFX shows hit effect
```

---

### Firebolt Ability

```text
Input
→ GameCommand("cast_ability", ability_id = "firebolt")
→ AbilityController validates cooldown and cost
→ StateMachine enters CastState
→ CastAction starts
→ ProjectileEffect spawns firebolt
→ Projectile hits enemy
→ DamageEffect is applied
→ CombatService calculates damage
→ EventService emits damage_applied
```

---

### Quest Progress

```text
Enemy dies
→ EventService emits enemy_died
→ QuestService receives event
→ Quest objective checks enemy type
→ Quest progress updates
→ EventService emits quest_progressed
→ Quest HUD updates
```

---

## Suggested Git Commit Style

Each lesson should end with a clean commit.

Examples:

```bash
git commit -m "course: add service registry bootstrap"
git commit -m "course: add command-driven player movement"
git commit -m "course: add action effect attack pipeline"
git commit -m "course: add combat damage resolution"
git commit -m "course: add firebolt ability"
git commit -m "course: add quest dialogue loop"
git commit -m "course: add save load flow"
```

This makes the course easier to follow and easier to debug.

---

## Suggested Free Preview Lessons

Good free-preview candidates:

```text
Lesson 1 — Course overview and final demo
Lesson 4 — Command-driven movement
Lesson 5 — First attack action
Lesson 7 — Damage popup and VFX feedback
```

These lessons show value quickly and help students decide whether the architecture style fits them.

---

## Future Course Ideas

This first course should focus on the core reusable kit.

Future advanced courses could cover:

```text
Advanced inventory and equipment
Procedural dungeon generation
Advanced enemy AI
Boss battle framework
Save migration
Editor tooling
Skill tree
Meta progression
Steam release pipeline
Mobile ads and IAP
Performance profiling
```

Possible follow-up course titles:

```text
Godot 4 Advanced RPG Systems: Inventory, Equipment, and Progression

Godot 4 Roguelike Dungeon Framework: Procedural Rooms, Rewards, and Runs

Godot 4 Indie Game Release Pipeline: From Prototype to Steam and Mobile
```

---

## Main Takeaway

This project is not only a demo game.

It is a reusable Godot 4 framework built through a real playable RPG / roguelike demo.

The course should teach students how to think in systems:

```text
Commands for intent
States for permission
Actions for timing
Effects for world changes
Services for domain logic
Events for feedback
Resources for data
Tests for confidence
```

By the end, students should have both:

```text
A playable 2D RPG / roguelike demo
A reusable MKit framework for future Godot projects
```
