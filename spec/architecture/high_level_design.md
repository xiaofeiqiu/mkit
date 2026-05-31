# Godot 2D RPG / Roguelike Mkit — Better Professional Framework

## 1. Executive Summary

This document defines a professional reusable 2D Mkit architecture for Godot, focused on RPG, roguelike, roguelite, action RPG, dungeon crawler, and survivor-like games.

The goal is not to build a rigid game template. The goal is to build a reusable gameplay foundation that can support multiple games with different combat styles, progression models, content structures, UI flows, monetization strategies, and platform integrations.

The optimized architecture is based on one core idea:

```text
Game-specific content should be replaceable.
Mkit runtime behavior should be reusable.
Game rules should be data-driven where possible.
Complex gameplay should be composed from small, explicit, testable modules.
```

The framework is organized around four architectural layers:

```text
Game Layer
  ↓
Gameplay Modules Layer
  ↓
Runtime Kernel Layer
  ↓
Platform / Infrastructure Layer
```

The most important improvement over a normal Godot game structure is that this Mkit separates:

```text
Data definition
Runtime state
Behavior orchestration
Gameplay resolution
Presentation feedback
Platform integration
```

This keeps the framework reusable, debuggable, and scalable.

---

# 2. Architecture Overview

## 2.1 Layered Architecture

```text
Game Layer
  ├── Game-specific player
  ├── Game-specific enemies
  ├── Game-specific bosses
  ├── Game-specific rooms
  ├── Game-specific abilities
  ├── Game-specific items
  ├── Game-specific UI screens
  └── Game-specific progression rules

Gameplay Modules Layer
  ├── Entity Module
  ├── Combat Module
  ├── Stats Module
  ├── Ability Module
  ├── Status Effect Module
  ├── Inventory / Equipment Module
  ├── Loot / Reward Module
  ├── Run Module
  ├── Room Module
  ├── Procedural Generation Module
  ├── Progression Module
  ├── AI Module
  ├── Interaction Module
  └── UI / Feedback Module

Runtime Kernel Layer
  ├── Lifecycle
  ├── Service Registry
  ├── Content Registry
  ├── Event Router
  ├── Command Router
  ├── HFSM / FSM
  ├── Action Runner
  ├── Condition Evaluator
  ├── Effect Executor
  ├── Gameplay Context
  ├── Save Framework
  ├── Random Service
  ├── Time Service
  ├── Object Pool
  └── Debug / Telemetry

Platform / Infrastructure Layer
  ├── Ads
  ├── IAP
  ├── Analytics
  ├── Cloud Save
  ├── Game Center / Achievements
  ├── File System
  └── External SDK Adapters
```

---

## 2.2 Dependency Direction

Dependencies should only go downward.

```text
Game Layer
  may depend on
Gameplay Modules
  may depend on
Runtime Kernel
  may depend on
Platform Interfaces
```

The Mkit must not depend on game-specific content.

Allowed:

```text
Game-specific FireballAbility uses AbilityController.
GoblinEnemy scene uses HealthComponent and EnemyBrain.
RewardSelectionUI listens to RewardSystem events.
```

Forbidden:

```text
CombatResolver knows about Fireball.
LootSystem knows about Goblin King.
SaveManager knows about a specific player scene.
AdService grants a specific revive reward directly.
```

---

# 3. Core Design Principles

## 3.1 Resource Defines, Instance Owns Runtime State

For reusable content, separate static definition from runtime instance.

```text
AbilityDefinition  → AbilityInstance
ItemDefinition     → ItemInstance
StatusDefinition   → StatusInstance
EntityDefinition   → EntityRoot / EntitySpawner
RoomDefinition     → RoomRuntime
UpgradeDefinition  → ProgressionState / ProgressionSystem
```

Rule:

```text
Resource = reusable content data
Instance = mutable runtime state
Node = scene-tree behavior
```

Example:

```text
ItemDefinition:
  item.sword_iron
  name = Iron Sword
  base attack = 5

ItemInstance:
  instance_id = item_000123
  definition_id = item.sword_iron
  affix = +12% crit chance
  durability = 82
```

This model is critical for RPGs because one item definition can produce many different runtime item instances.

---

## 3.2 Entity Is Composition, Not Inheritance

A gameplay entity should be a scene composed of components, controllers, behavior, and presentation.

Example:

```text
PlayerEntity.tscn
  ├── CharacterBody2D
  ├── EntityRoot
  ├── Components
  │   ├── HealthComponent
  │   ├── StatsComponent
  │   ├── MovementComponent
  │   ├── HurtboxComponent
  │   ├── HitboxEmitter
  │   └── StatusEffectController
  ├── Controllers
  │   ├── AbilityController
  │   ├── InventoryController
  │   └── EquipmentController
  ├── Behavior
  │   ├── StateMachine
  │   └── CommandReceiver
  └── Presentation
      ├── SpriteRoot
      ├── AnimationPlayer
      ├── AudioEmitter
      └── VFXAnchor
```

Avoid deep inheritance chains.

Bad:

```text
Entity → LivingEntity → CombatEntity → PlayerEntity → RoguePlayerEntity
```

Good:

```text
Entity = Scene + Components + Controllers + Data + Behavior
```

---

## 3.3 Commands Represent Intent

Commands are not effects. Commands are intent.

Examples:

```text
MoveCommand
AttackCommand
CastAbilityCommand
DashCommand
InteractCommand
SelectRewardCommand
OpenInventoryCommand
PauseCommand
```

The same command can come from:

```text
Player input
AI
Tutorial script
Replay system
Automation test
Network input in the future
```

Recommended flow:

```text
Input / AI / Script
  ↓
Command
  ↓
Command Router
  ↓
HFSM / Controller
  ↓
Action / Ability / Effect
```

---

## 3.4 HFSM Owns Behavior Mode, Not Gameplay Rules

HFSM should answer:

```text
What behavior mode is this entity currently in?
What transitions are allowed?
What command is valid in the current state?
```

HFSM should not own:

```text
Damage formula
Loot generation
Inventory mutation
Stat calculation
Ad reward grant
Save file structure
```

Example:

```text
AttackState starts AttackAction.
AttackAction triggers Hitbox / Effect.
CombatResolver calculates damage.
HealthComponent applies damage.
LootSystem reacts to death event.
```

---

## 3.5 Actions Own Time-Based Execution

An action represents a process that takes time.

Examples:

```text
Attack startup / active / recovery
Dash for 0.2 seconds
Cast spell for 1 second
Move to target
Wait for animation
Spawn projectile after delay
Channel beam until cancelled
```

State is the mode.

Action is the timed process.

Effect is the gameplay result.

```text
State → Action → Effect → Domain System
```

---

## 3.6 Effects Are Declarative Gameplay Outcomes

Effects represent what happens, not when or why it happens.

Examples:

```text
DealDamageEffect
HealEffect
ApplyStatusEffect
ModifyStatEffect
SpawnSceneEffect
GrantItemEffect
GrantCurrencyEffect
UnlockAbilityEffect
StartCooldownEffect
PlayVFXEffect
PlaySoundEffect
```

Effects should be:

```text
Composable
Serializable
Inspectable
Reusable
Restricted
Data-driven
```

Avoid arbitrary script execution inside effects unless explicitly required.

---

## 3.7 Events Are Notifications, Not Control Flow

Events should announce what happened.

They should not become the main way systems command each other.

Good event examples:

```text
entity_died
damage_applied
item_collected
inventory_changed
room_cleared
reward_selected
run_started
run_failed
```

Bad event usage:

```text
EventBus.emit("please_calculate_damage")
EventBus.emit("force_inventory_to_add_item")
EventBus.emit("make_enemy_attack_player")
```

Rule:

```text
Use Commands for intent.
Use APIs for direct domain operations.
Use Events for notifications.
```

---

# 4. Runtime Kernel

The Runtime Kernel is the reusable engine inside the Mkit. It provides generic mechanisms that all gameplay modules depend on.

---

## 4.1 Lifecycle System

The Mkit should have an explicit lifecycle.

Recommended lifecycle:

```text
Boot
  ↓
Register Services
  ↓
Load Config
  ↓
Load Content Registry
  ↓
Initialize Runtime Systems
  ↓
Load Profile / Save Data
  ↓
Enter Main Menu or Start Run
```

Recommended autoload (keep it minimal — exactly one true global):

```text
ServiceRegistry      # the only addon autoload; global service locator
```

`GameBootstrap` is NOT an autoload. It is a node the host game places in its main
scene, because it references game-specific content (`resource_databases`,
`initial_scene_path`). On boot it constructs the remaining long-lived systems
(`EventRouter`, `ContentRegistry`, `CommandRouter`, `SceneRouter`, `SaveManager`,
`ProgressionSystem`, `RandomService`, `TimeService`, `ActionRunner`,
`EffectExecutor`, `ObjectPool`, and an optional `DebugOverlay`) and registers them
in `ServiceRegistry`. Every other system reaches them with
`ServiceRegistry.get_service(id)`, never as separate autoloads — this keeps startup
order explicit and avoids duplicate singleton instances.

Avoid making every system an Autoload. Use Autoload only for the single locator.

Note (Godot constraint): an autoload name cannot collide with a `class_name`.
Because the autoload is named `ServiceRegistry`, its script must NOT also declare
`class_name ServiceRegistry`; reach it through the autoload global instead.

---

## 4.2 Service Registry

Instead of hardcoding global references everywhere, use a lightweight service registry.

Purpose:

```text
Register global services
Resolve dependencies
Allow mock services in tests
Allow platform-specific implementations
```

Example services:

```text
RandomService
TimeService
AnalyticsService
AdService
IAPService
SaveManager
ContentRegistry
ObjectPool
```

Example API:

```gdscript
ServiceRegistry.register("random", RandomService)
var random = ServiceRegistry.get_service("random")
```

Use this carefully. It should not become a dumping ground for gameplay objects.

---

## 4.3 Content Registry

RPG and roguelike games have many data resources.

A central registry is needed for stable lookup and validation.

The registry maps stable IDs to Resources.

Examples:

```text
item.sword_iron          → ItemDefinition
ability.fireball_basic   → AbilityDefinition
enemy.goblin_basic       → EntityDefinition
room.dungeon_small_01    → RoomDefinition
upgrade.attack_plus_20   → UpgradeDefinition
status.burn              → StatusEffectDefinition
loot.goblin_common       → LootTableDefinition
```

Responsibilities:

```text
Load resource databases
Validate duplicate IDs
Validate missing references
Provide lookup by ID
Support save/load restoration
Support editor-time validation
```

This is critical because save files should store stable IDs, not raw Resource paths whenever possible.

---

## 4.4 Event Router

The Event Router dispatches domain events.

Prefer typed signals for major events.

Example:

```gdscript
signal damage_applied(result)
signal entity_died(entity_id, entity_ref)
signal item_collected(item_instance)
signal inventory_changed(owner_id)
signal room_cleared(room_id)
signal reward_selected(reward_id)
signal run_started(run_id, seed)
signal run_finished(run_id, result)
```

Rules:

```text
Events should be past-tense facts.
Events should be easy to log.
Events should be safe to ignore.
Events should not require a return value.
```

---

## 4.5 Command Router

The Command Router sends commands to the correct receiver.

Command receiver examples:

```text
Player CommandReceiver
Enemy AI CommandReceiver
Run CommandReceiver
UI CommandReceiver
Room CommandReceiver
```

Command contract:

```gdscript
class_name GameCommand
extends RefCounted

var command_id: String
var command_type: String
var source_id: String
var target_id: String
var timestamp: float
var payload: Dictionary
```

Examples:

```text
move
attack
cast_ability
dash
interact
select_reward
pause
resume
```

---

## 4.6 HFSM Kernel

HFSM is required for serious RPG / roguelike behavior because flat FSM becomes difficult to maintain as states grow.

Use one unified state machine that supports both flat FSM and hierarchical FSM.

Flat FSM is simply an HFSM with one level.

### State Responsibilities

A state may:

```text
Enter behavior mode
Exit behavior mode
Update behavior
Handle commands
Start actions
Request transitions
Evaluate guards
```

A state should not:

```text
Calculate combat damage
Generate loot
Mutate save file directly
Call ad SDK directly
Own inventory UI
```

### State Contract

```gdscript
class_name State
extends Node

var state_id: String
var parent_state: State
var state_machine: StateMachine
var owner_entity: Node

func enter(context: Dictionary = {}) -> void:
    pass

func exit(context: Dictionary = {}) -> void:
    pass

func update(delta: float) -> void:
    pass

func physics_update(delta: float) -> void:
    pass

func handle_command(command: GameCommand) -> bool:
    return false

func can_enter(context: Dictionary = {}) -> bool:
    return true

func can_exit(context: Dictionary = {}) -> bool:
    return true
```

### Transition Algorithm

Use Lowest Common Ancestor transition logic.

Example:

```text
Current:
Player / Alive / Locomotion / Move

Target:
Player / Alive / Combat / BasicAttack

Common ancestor:
Player / Alive

Exit:
Move
Locomotion

Enter:
Combat
BasicAttack
```

This gives clean global override transitions like:

```text
Player / Alive / Combat / BasicAttack
  → Player / Dead
```

---

## 4.7 Action Runner

The Action Runner updates active actions.

Actions should be independent from states when possible.

Action contract:

```gdscript
class_name GameAction
extends RefCounted

signal completed
signal cancelled

func start(context: ActionContext) -> void:
    pass

func update(delta: float) -> void:
    pass

func cancel(reason: String = "") -> void:
    pass

func is_finished() -> bool:
    return false
```

Example actions:

```text
TimedAttackAction
DashAction
CastAction
ChannelAction
SpawnAfterDelayAction
WaitForAnimationAction
MoveToTargetAction
```

---

## 4.8 Condition Evaluator

Conditions are reusable rule checks.

Condition examples:

```text
HasEnoughMana
CooldownReady
HasItem
HasTag
TargetInRange
HealthBelowPercent
RoomCleared
RandomChance
AnimationCancelable
```

Condition contract:

```gdscript
class_name Condition
extends Resource

func evaluate(context: GameplayContext) -> bool:
    return true
```

Used by:

```text
HFSM transition guards
Ability cast validation
Equipment validation
Reward eligibility
Loot eligibility
AI decisions
Room entry rules
```

---

## 4.9 Effect Executor

Effect Executor applies effects in a controlled way.

Effect contract:

```gdscript
class_name GameEffect
extends Resource

func apply(context: GameplayContext) -> EffectResult:
    return EffectResult.new()
```

Effect execution should be traceable.

For debugging, every effect application should report:

```text
Effect ID
Source entity
Target entity
Input context
Result
Success / failure
Failure reason
```

---

## 4.10 Gameplay Context

Instead of passing raw `Dictionary` everywhere long-term, define a typed context wrapper.

Initial implementation can use Dictionary.

Professional implementation should use context objects.

Example:

```gdscript
class_name GameplayContext
extends RefCounted

var source: Node
var target: Node
var ability_id: String
var item_id: String
var room_id: String
var run_id: String
var position: Vector2
var direction: Vector2
var payload: Dictionary
```

This improves readability and reduces key-name bugs.

---

# 5. Gameplay Modules

## 5.1 Entity Module

The Entity Module defines runtime game objects and their reusable components.

### Entity Metadata

```gdscript
class_name EntityIdentity
extends Node

var entity_id: String
var definition_id: String
var faction: String
var tags: Array[String]
```

Common factions:

```text
player
enemy
neutral
environment
summon
```

Common tags:

```text
player
enemy
boss
projectile
summon
trap
destructible
pickup
npc
```

### Core Components

```text
HealthComponent
StatsComponent
MovementComponent
HitboxEmitter
HurtboxReceiver
StatusEffectController
AbilityController
InventoryController
EquipmentController
InteractionComponent
```

Rule:

```text
Components own local state and capability.
Systems own cross-entity rules.
```

---

## 5.2 Stats Module

Stats Module owns stat definitions, modifiers, and final value calculation.

### Stat Examples

```text
max_hp
attack_power
defense
move_speed
attack_speed
crit_chance
crit_damage
cooldown_reduction
luck
pickup_range
projectile_count
area_multiplier
damage_multiplier
healing_multiplier
```

### Modifier Types

```text
FlatAdd
PercentAdd
PercentMultiply
Override
ClampMin
ClampMax
```

### Calculation Order

Recommended:

```text
Base Value
  → Flat Add
  → Percent Add
  → Percent Multiply
  → Override if any
  → Clamp
```

Each modifier should include:

```text
modifier_id
stat_id
source_id
operation
value
duration
priority
stacking_rule
```

This is important for buffs, equipment, run upgrades, debuffs, and temporary room effects.

---

## 5.3 Combat Module

Combat Module owns damage resolution.

### Damage Flow

```text
Hitbox detects Hurtbox
  ↓
DamageRequest created
  ↓
CombatResolver resolves request
  ↓
DamageResult produced
  ↓
HealthComponent applies result
  ↓
Events emitted
  ↓
Audio / VFX / UI / Loot react
```

### DamageRequest

```gdscript
class_name DamageRequest
extends RefCounted

var source: Node
var target: Node
var base_amount: float
var damage_type: String
var element_type: String
var can_crit: bool
var tags: Array[String]
var payload: Dictionary
```

### DamageResult

```gdscript
class_name DamageResult
extends RefCounted

var source: Node
var target: Node
var final_amount: float
var was_critical: bool
var was_evaded: bool
var was_blocked: bool
var was_lethal: bool
var applied_status_effects: Array
```

CombatResolver owns:

```text
Attack stat reading
Defense stat reading
Critical calculation
Element modifiers
Damage reduction
Evasion / block
Final damage calculation
```

CombatResolver does not own:

```text
Loot drop
Death animation
UI display
Enemy AI transition
```

---

## 5.4 Health Module

HealthComponent owns HP state.

Responsibilities:

```text
Track current HP
Track max HP
Apply damage result
Apply healing
Emit health changed
Emit damaged
Emit healed
Emit died
```

It should not calculate damage.

It should not generate loot.

It should not update UI directly.

---

## 5.5 Ability Module

Ability Module owns active and passive ability execution.

### AbilityDefinition

```gdscript
class_name AbilityDefinition
extends Resource

var ability_id: String
var display_name: String
var description: String
var cooldown: float
var charges: int
var cost_type: String
var cost_amount: float
var cast_time: float
var range: float
var tags: Array[String]
var conditions: Array[Condition]
var actions: Array[ActionDefinition]
var effects: Array[GameEffect]
```

### AbilityInstance

Runtime ability state:

```text
Owner entity
Cooldown remaining
Current charges
Temporary modifiers
Runtime level
Enabled / disabled
```

### AbilityController Responsibilities

```text
Register abilities
Check conditions
Check cost
Check cooldown
Start cast action
Execute effects
Start cooldown
Cancel ability
Emit ability events
```

Recommended ability flow:

```text
CastAbilityCommand
  ↓
HFSM validates current behavior state
  ↓
AbilityController.can_cast()
  ↓
CastAction starts
  ↓
Effects execute at configured timing
  ↓
Cooldown starts
  ↓
Events emitted
```

---

## 5.6 Status Effect Module

Status Effect Module owns buffs, debuffs, and temporary gameplay effects.

### StatusEffectDefinition

```gdscript
class_name StatusEffectDefinition
extends Resource

var status_id: String
var display_name: String
var duration: float
var tick_interval: float
var max_stacks: int
var stack_rule: String
var tags: Array[String]
var effects_on_apply: Array[GameEffect]
var effects_on_tick: Array[GameEffect]
var effects_on_remove: Array[GameEffect]
var stat_modifiers: Array[StatModifierDefinition]
```

### Stack Rules

```text
RefreshDuration
AddStack
Replace
Ignore
ExtendDuration
IndependentStacks
```

### StatusEffectController Responsibilities

```text
Apply status
Remove status
Tick status
Handle stacking
Apply stat modifiers
Remove stat modifiers
Emit status events
```

---

## 5.7 Item / Inventory / Equipment Module

This module owns item storage, item instances, and equipment rules.

### ItemDefinition

```gdscript
class_name ItemDefinition
extends Resource

var item_id: String
var display_name: String
var description: String
var item_type: String
var rarity: String
var icon: Texture2D
var stackable: bool
var max_stack: int
var tags: Array[String]
var use_conditions: Array[Condition]
var use_effects: Array[GameEffect]
var stat_modifiers: Array[StatModifierDefinition]
```

### ItemInstance

Runtime item state:

```text
instance_id
definition_id
quantity
rolled_affixes
durability
upgrade_level
bound_modifiers
metadata
```

### Inventory Responsibilities

```text
Add item
Remove item
Stack item
Move item
Find item
Serialize inventory
Emit inventory changed
```

### Equipment Responsibilities

```text
Validate slot
Equip item
Unequip item
Apply stat modifiers
Remove stat modifiers
Emit equipment changed
```

Inventory should not know UI layout.

Equipment should not directly update UI.

---

## 5.8 Loot / Reward Module

Loot and Reward are related but should be separated.

### Loot System

LootSystem generates rewards from loot tables.

Used by:

```text
Enemy drops
Chest drops
Boss drops
Room drops
Shop stock generation
```

LootSystem returns generated results.

It should not automatically add items to inventory unless explicitly called by a higher-level flow.

### Reward System

RewardSystem manages player-facing choices.

Examples:

```text
Choose one of three upgrades
Choose one item from chest
Choose one ability after room clear
Choose revive reward
Choose shop purchase
```

RewardOption should be built from:

```text
Display data
Conditions
Effects
Weight / rarity
Source
```

Room reward flow:

```text
Room cleared
  ↓
RunDirector requests reward options
  ↓
RewardSystem generates choices
  ↓
UI displays choices
  ↓
Player selects reward
  ↓
RewardSystem applies selected effects
  ↓
RunDirector advances run
```

---

## 5.9 Run Module

Run Module owns the roguelike session.

### RunState

```text
run_id
seed
current_floor
current_room_id
elapsed_time
temporary_upgrades
run_currency
enemy_scaling_level
room_history
reward_history
rng_state
```

### RunDirector

RunDirector coordinates the run lifecycle.

Responsibilities:

```text
Start run
Generate dungeon
Enter room
Track room clear
Trigger rewards
Advance floor
Handle death
Complete run
Fail run
Pause / resume run
```

RunDirector should use an HFSM.

Recommended Run HFSM:

```text
Run
  ├── NotStarted
  ├── Starting
  ├── Active
  │   ├── Exploring
  │   ├── InCombat
  │   ├── ChoosingReward
  │   └── Paused
  ├── Completed
  └── Failed
```

---

## 5.10 Room Module

Room Module owns room lifecycle.

Recommended Room HFSM:

```text
Room
  ├── Unloaded
  ├── Loading
  ├── Entering
  ├── Active
  │   ├── Spawning
  │   ├── Combat
  │   └── WaitingForClear
  ├── Cleared
  │   ├── GeneratingReward
  │   └── RewardAvailable
  └── Completed
```

RoomController responsibilities:

```text
Spawn enemies
Track active enemies
Open / close doors
Detect clear condition
Request reward generation
Notify RunDirector
```

---

## 5.11 Procedural Generation Module

Procedural Generation should be deterministic when given the same seed.

Initial scope:

```text
Linear dungeon path
Optional branches
Room type selection
Enemy spawn points
Chest / reward placement
Boss room placement
```

Future scope:

```text
Graph dungeon
Biome rules
Difficulty curves
Procedural tile placement
Dynamic events
Secret rooms
Elite rooms
Shop rooms
```

### RoomDefinition

```gdscript
class_name RoomDefinition
extends Resource

var room_id: String
var scene_path: String
var room_type: String
var difficulty_rating: int
var size: Vector2i
var tags: Array[String]
var spawn_rules: Array
var reward_rules: Array
```

---

## 5.12 Progression Module

Progression should support two categories:

```text
Run Progression: temporary upgrades during a run
Meta Progression: permanent unlocks across runs
```

### UpgradeDefinition

```gdscript
class_name UpgradeDefinition
extends Resource

var upgrade_id: String
var display_name: String
var description: String
var rarity: String
var tags: Array[String]
var conditions: Array[Condition]
var effects: Array[GameEffect]
```

Examples:

```text
+20% attack for current run
+1 projectile
Unlock fireball
Permanent max HP +5
Start each run with extra gold
Add new item to loot pool
```

---

## 5.13 AI Module

AI should produce commands, not directly mutate gameplay systems.

Recommended flow:

```text
AI Brain
  ↓
Command
  ↓
HFSM
  ↓
Action / Ability
  ↓
Effect / Combat
```

### AI Levels

Use three levels:

```text
SimpleAI
BehaviorTreeAI
UtilityAI
```

### SimpleAI

Good for early implementation.

Examples:

```text
Chase player
Attack if in range
Retreat if low HP
Patrol if player not visible
```

### Behavior Tree

Good for structured enemy and boss behavior.

Example:

```text
Selector
  ├── Sequence
  │   ├── IsTargetInAttackRange
  │   └── IssueAttackCommand
  ├── Sequence
  │   ├── CanSeeTarget
  │   └── IssueChaseCommand
  └── IssuePatrolCommand
```

### Utility AI

Good for advanced bosses and dynamic enemies.

Utility AI can be implemented later.

Do not build Utility AI before the core combat loop is stable.

---

## 5.14 UI Module

UI should be reactive, not tightly coupled to gameplay internals.

UI should communicate intent through commands or domain APIs.

Gameplay systems should notify UI through events or view models.

Recommended UI flow:

```text
Player clicks equip item
  ↓
InventoryUI sends EquipItemCommand or calls EquipmentController API
  ↓
EquipmentController equips item
  ↓
StatsComponent recalculates
  ↓
Events emitted
  ↓
UI refreshes from view model
```

### UIManager Responsibilities

```text
Open screen
Close screen
Stack popup
Block gameplay input
Route UI commands
Handle pause behavior
Manage modal screens
```

Common screens:

```text
HUD
Inventory
Equipment
Reward Selection
Shop
Pause Menu
Settings
Game Over
Run Summary
```

---

## 5.15 Audio / VFX / Feedback Module

Audio and VFX should react to gameplay events.

Recommended flow:

```text
Combat event emitted
  ↓
FeedbackSystem receives event
  ↓
VFXSpawner spawns hit effect
  ↓
AudioManager plays hit sound
  ↓
DamageNumberSystem displays number
```

This prevents combat code from directly controlling presentation.

---

## 5.16 Save / Load Module

SaveManager coordinates persistence but should not know every internal detail.

Systems that need persistence should implement a save contract.

### Saveable Contract

```gdscript
class_name Saveable
extends Node

func get_save_id() -> String:
    return ""

func to_save_data() -> Dictionary:
    return {}

func from_save_data(data: Dictionary) -> void:
    pass
```

### Save File Structure

```json
{
  "save_version": 1,
  "game_version": "0.1.0",
  "timestamp": "2026-05-30T18:00:00",
  "profile_id": "profile_001",
  "payload": {
    "player": {},
    "inventory": {},
    "equipment": {},
    "meta_progression": {},
    "run": {},
    "settings": {}
  }
}
```

### Save Rules

Store stable IDs, not scene references.

Good:

```text
item_id = "item.sword_iron"
ability_id = "ability.fireball_basic"
room_id = "room.dungeon_small_01"
```

Avoid saving fragile runtime details unless required:

```text
Current animation frame
Dash timer
Attack startup frame
Temporary transition context
```

For most games:

```text
Save player long-term state exactly.
Save run state if mid-run save is supported.
Restore player behavior to a safe state such as Idle.
```

---

# 6. Recommended Core Flows

## 6.1 Player Attack Flow

```text
InputReader reads attack button
  ↓
AttackCommand created
  ↓
Player CommandReceiver receives command
  ↓
Player HFSM checks current state
  ↓
HFSM transitions to Alive / Combat / BasicAttack
  ↓
BasicAttackState starts TimedAttackAction
  ↓
AttackAction activates hitbox during active frames
  ↓
Hitbox detects Hurtbox
  ↓
CombatResolver resolves damage
  ↓
HealthComponent applies result
  ↓
Events emitted
  ↓
Audio / VFX / UI react
```

---

## 6.2 Ability Cast Flow

```text
CastAbilityCommand
  ↓
HFSM validates behavior state
  ↓
AbilityController checks cooldown, cost, and conditions
  ↓
CastAction starts
  ↓
EffectExecutor applies configured effects
  ↓
Projectile / damage / status effects occur
  ↓
Cooldown starts
  ↓
Ability events emitted
  ↓
UI updates cooldown display
```

---

## 6.3 Enemy AI Flow

```text
EnemyBrain evaluates situation
  ↓
AI creates ChaseCommand or AttackCommand
  ↓
Enemy CommandReceiver receives command
  ↓
Enemy HFSM transitions state
  ↓
Action executes movement or attack
  ↓
Combat system resolves result
```

---

## 6.4 Room Clear Reward Flow

```text
Enemy dies
  ↓
RoomController tracks remaining enemies
  ↓
RoomController detects room cleared
  ↓
Room event emitted
  ↓
RunDirector enters ChoosingReward state
  ↓
RewardSystem generates reward options
  ↓
UIManager opens reward selection screen
  ↓
Player selects reward
  ↓
RewardSystem applies effects
  ↓
RunDirector advances to next room
```

---

## 6.5 Item Pickup Flow

```text
Player overlaps pickup
  ↓
Pickup creates CollectItemRequest
  ↓
Inventory validates capacity and stack rules
  ↓
ItemInstance added
  ↓
InventoryChanged event emitted
  ↓
UI / Audio / Analytics react
```

---

## 6.6 Death Flow

```text
DamageResult is lethal
  ↓
HealthComponent reaches 0 HP
  ↓
HealthComponent emits died
  ↓
EntityDeathSystem handles death flow
  ↓
Enemy HFSM transitions to Dead
  ↓
LootSystem may generate drops
  ↓
RoomController updates enemy count
  ↓
VFX / Audio play death feedback
```

---

# 7. Recommended Folder Structure

Mkit ships as a self-contained Godot **addon** under `res://addons/mkit/`.
Everything reusable lives inside that one folder, so the kit can be dropped into
(or removed from) any project by copying a single directory or adding a git
submodule. Game-specific content lives outside the addon under `res://game/` and
depends on Mkit only through its public APIs (ServiceRegistry, CommandRouter,
EventRouter, base classes / Resources). Dependencies always point inward
(`game/ -> addons/mkit/`), never the reverse.

## 7.1 Addon Layout (reusable, distributable)

```text
res://addons/mkit/

  plugin.cfg                 # Godot addon manifest (name, version, entry script)
  plugin.gd                  # EditorPlugin: registers/removes autoloads + editor tooling

  kernel/
    bootstrap/
      game_bootstrap.gd
    services/
      service_registry.gd
      scene_router.gd
      random_service.gd
      random_stream.gd
      time_service.gd
      object_pool.gd
    events/
      event_router.gd
      domain_events.gd
    commands/
      game_command.gd
      command_router.gd
      command_receiver.gd
    state_machine/
      state.gd
      composite_state.gd
      state_machine.gd
      transition_rule.gd
      state_path.gd
      debug/
    actions/
      game_action.gd
      action_runner.gd
    conditions/
      condition.gd
      condition_evaluator.gd
      builtin/
    effects/
      game_effect.gd
      effect_executor.gd
      effect_result.gd
      builtin/
    context/
      gameplay_context.gd
      blackboard.gd
      action_context.gd
    registry/
      content_registry.gd
      resource_database.gd
      content_validator.gd
    debug/
      debug_overlay.gd
      gameplay_trace.gd

  modules/
    entity/
      entity_identity.gd
      entity_lifecycle.gd
      components/
    stats/
      stat_definition.gd
      stat_modifier.gd
      stats_component.gd
    health/
      health_component.gd
    combat/
      damage_request.gd
      damage_result.gd
      combat_resolver.gd
      hitbox_component.gd
      hurtbox_component.gd
    abilities/
      ability_definition.gd
      ability_instance.gd
      ability_controller.gd
    status_effects/
      status_effect_definition.gd
      status_effect_instance.gd
      status_effect_controller.gd
    inventory/
      item_definition.gd
      item_instance.gd
      inventory_model.gd
      inventory_controller.gd
    equipment/
      equipment_slot.gd
      equipment_controller.gd
    loot/
      loot_table_definition.gd
      loot_entry.gd
      loot_system.gd
    rewards/
      reward_definition.gd
      reward_option.gd
      reward_system.gd
    run/
      run_state.gd
      run_director.gd
      run_fsm/
    rooms/
      room_definition.gd
      room_controller.gd
      room_fsm/
    procedural_generation/
      dungeon_generator.gd
      room_graph.gd
      generation_rules.gd
    progression/
      upgrade_definition.gd
      progression_system.gd
    ai/
      brain.gd
      simple_ai/
      behavior_tree/
      utility_ai/
    interaction/
      interaction_component.gd
      interactable.gd
    save/
      save_manager.gd
      saveable.gd
      save_migration.gd
    ui/
      ui_manager.gd
      view_models/
    feedback/
      audio_manager.gd
      vfx_spawner.gd
      damage_number_system.gd

  platform/
    ads/
      ad_service.gd
      ad_service_mock.gd
      ad_service_mobile.gd
    analytics/
      analytics_service.gd
      analytics_service_mock.gd
    iap/
      iap_service.gd
      iap_service_mock.gd
    cloud_save/
      cloud_save_service.gd

  resources/                 # base Resource types + built-in/example definitions
    stats/
    items/
    abilities/
    status_effects/
    effects/
    conditions/
    loot_tables/
    rewards/
    upgrades/
    enemies/
    rooms/

  ui/                        # reusable, game-agnostic presentation assets
    theme/                   #   base theme(s)
    widgets/                 #   generic controls (bars, tooltips, list cells)
    transitions/             #   scene-flow transition scenes

  editor/                    # editor-only tooling (content/save inspectors + validators)

  tests/                     # Mkit's own headless tests + fixtures

  README.md
  LICENSE
```

## 7.2 Host Game Layout (per-project, not part of the addon)

```text
res://game/

  content/                   # concrete definition Resources (stable IDs)
    items/
    abilities/
    enemies/
    rooms/
    upgrades/
  player/                    # concrete player scene (composed from mkit components)
  enemies/
  bosses/
  rooms/
  ui/                        # concrete screens built from mkit widgets/view models
  scenes/
  art/
  audio/

res://project.godot          # enables the plugin; autoloads injected by plugin.gd
```

## 7.3 Addon Mechanics

`plugin.cfg` is the manifest Godot reads to list and enable the addon:

```text
[plugin]
name="Mkit"
description="Reusable 2D RPG / roguelike runtime kernel and gameplay modules."
author="..."
version="0.1.0"
script="plugin.gd"
```

`plugin.gd` registers only the single global locator autoload when the addon is
enabled and removes it when disabled. Everything else is constructed by the host
game's `GameBootstrap` node and registered into `ServiceRegistry` (see Section 4.1),
so the addon never injects game-specific autoloads:

```gdscript
@tool
extends EditorPlugin

const AUTOLOADS := {
    "ServiceRegistry": "res://addons/mkit/kernel/services/service_registry.gd",
}

func _enter_tree() -> void:
    for autoload_name in AUTOLOADS:
        add_autoload_singleton(autoload_name, AUTOLOADS[autoload_name])

func _exit_tree() -> void:
    for autoload_name in AUTOLOADS:
        remove_autoload_singleton(autoload_name)
```

> `service_registry.gd` must not declare `class_name ServiceRegistry` (it would
> collide with this autoload name). All other kernel scripts keep their
> `class_name` because they are plain classes, not autoloads.

## 7.4 Boundary Rules (keep reuse clean)

```text
The addon never references res://game/... ; dependencies point only inward.
New games register their own services / receivers / signals through
  ServiceRegistry, CommandRouter, and EventRouter instead of editing addon code.
Concrete content (definitions, scenes, art) lives in res://game/, not the addon.
Distribute by copying res://addons/mkit/ or adding it as a git submodule;
  nothing outside that folder is required for the kit to function.
```

---

# 8. Recommended MVP Implementation Plan

A better implementation plan should be based on vertical slices, not just system-by-system construction.

Each phase should produce a playable validation demo.

---

## Phase 0: Kernel Prototype

Build only the core runtime primitives.

Implement:

```text
ServiceRegistry
EventRouter
ContentRegistry
GameCommand
CommandReceiver
HFSM
ActionRunner
Condition
GameEffect
GameplayContext
RandomService
Debug trace basics
```

Validation:

```text
Create a dummy entity.
Send command.
State changes.
Action runs.
Effect logs result.
Debug overlay shows state path.
```

---

## Phase 1: Combat Vertical Slice

Implement:

```text
Player entity
Enemy entity
HealthComponent
StatsComponent
Hitbox / Hurtbox
CombatResolver
BasicAttackAction
DealDamageEffect
Death event
Basic VFX / Audio hook
```

Validation:

```text
Player moves.
Player attacks.
Enemy takes damage.
Enemy dies.
Death event is emitted.
```

This proves the most important pipeline:

```text
Command → HFSM → Action → Effect → Combat → Event → Feedback
```

---

## Phase 2: Ability and Status Slice

Implement:

```text
AbilityDefinition
AbilityInstance
AbilityController
CastAbilityCommand
Projectile spawn effect
StatusEffectDefinition
StatusEffectController
Burn or Poison status
Cooldown UI
```

Validation:

```text
Player casts fireball.
Fireball damages enemy.
Burn ticks over time.
Cooldown appears on HUD.
```

---

## Phase 3: Item / Inventory / Equipment Slice

Implement:

```text
ItemDefinition
ItemInstance
InventoryModel
InventoryController
EquipmentController
StatModifier
Pickup flow
Simple inventory UI
```

Validation:

```text
Enemy drops sword.
Player picks up sword.
Sword appears in inventory.
Player equips sword.
Attack stat increases.
```

---

## Phase 4: Room and Run Slice

Implement:

```text
RoomController
Room HFSM
RunDirector
Run HFSM
Simple DungeonGenerator
Room clear detection
RewardSystem
UpgradeDefinition
Reward selection UI
```

Validation:

```text
Start run.
Enter room.
Clear enemies.
Choose reward.
Enter next room.
Die or complete run.
```

---

## Phase 5: Save and Meta Progression

Implement:

```text
SaveManager
Saveable contract
Save versioning
Meta progression
Unlocked abilities
Permanent upgrades
Settings save
```

Validation:

```text
Complete a run.
Gain currency.
Buy permanent upgrade.
Restart game.
Upgrade persists.
```

---

## Phase 6: Platform Services

Implement interfaces first.

```text
AnalyticsService
AdService
IAPService
CloudSaveService
```

Use mock implementations in development.

Validation:

```text
Track run events.
Show mock rewarded ad.
Grant revive reward.
Purchase mock product.
```

Only integrate real SDKs after gameplay flow is stable.

---

# 9. What Should Be Deferred

Do not implement everything immediately.

Defer these until the base game loop is working:

```text
Utility AI
Advanced Behavior Tree editor
Complex procedural tile generation
Quest system
Dialogue graph
Cloud save
Game Center
Advanced analytics dashboard
Mod support
Multiplayer
ECS framework
Visual scripting editor
```

These are useful but not required for the first reusable Mkit.

---

# 10. Professional Debugging Requirements

A reusable Mkit must be debuggable.

Minimum debug features:

```text
Current HFSM state path
Previous HFSM state path
Last command received
Last transition reason
Failed transition reason
Active actions
Active status effects
Current stat values
Active stat modifiers
Last damage calculation trace
Current room state
Current run state
Random seed and stream state
Recent domain events
```

Example debug output:

```text
Player
  State: Player / Alive / Locomotion / Move
  Last Command: MoveCommand
  Active Action: None
  HP: 82 / 100
  Attack: 15.0
  Modifiers:
    - sword_iron_attack +5 flat
    - upgrade_attack_20 +20% additive

Combat Trace
  Source: player
  Target: goblin_01
  Base Damage: 10
  Attack Modifier: +5
  Crit: false
  Defense Reduction: -3
  Final Damage: 12
```

This will save enormous development time.

---

# 11. Final Recommended Architecture

The best version of this Mkit should be built around the following core pipeline:

```text
Input / AI / Script
  ↓
Command
  ↓
HFSM
  ↓
Action
  ↓
Effect
  ↓
Domain System
  ↓
Event
  ↓
UI / Audio / VFX / Analytics
```

And the following data model:

```text
Definition Resource
  ↓
Runtime Instance
  ↓
Controller / Component
  ↓
System / Resolver
```

Most important reusable systems:

```text
Runtime Kernel
Entity Composition
HFSM
Command Router
Action Runner
Condition Evaluator
Effect Executor
Content Registry
Stats System
Combat Resolver
Ability System
Status Effect System
Inventory / Equipment
Loot / Reward
Run Director
Room Controller
Save Framework
UI Manager
Feedback System
Platform Service Interfaces
```

The first serious production-quality milestone should not be “all systems completed.”

The first milestone should be:

```text
A playable vertical slice where:

Player moves.
Player attacks.
Enemy reacts.
Enemy dies.
Loot drops.
Item is collected.
Reward is selected.
Run advances.
State/debug information is visible.
```

If that vertical slice is clean, then the rest of the Mkit can grow safely.

---

# 12. Key Architectural Boundary

The most important boundary is:

```text
Mkit provides reusable mechanisms.
Game-specific code provides concrete content and rules.
```

Mkit should know:

```text
AbilityDefinition
ItemDefinition
DamageRequest
RewardOption
RunState
RoomDefinition
Condition
Effect
Command
State
```

Mkit should not know:

```text
Fireball of the Red Mage
Goblin King Boss
Iron Sword of Chapter 2
Forest Dungeon Room 3
Specific revive ad economy
Specific shop pricing strategy
Specific story progression
```

This boundary is what makes the framework reusable across multiple RPG / roguelike games.

---

# 13. Final Recommendation

Build this Mkit as a small reusable runtime kernel plus modular gameplay packages.

Do not start by building every module fully.

Start by proving this pipeline:

```text
Command → HFSM → Action → Effect → Combat → Event → UI/VFX
```

Then add systems only when the vertical slice needs them.

This gives you a professional architecture without falling into over-engineering.


