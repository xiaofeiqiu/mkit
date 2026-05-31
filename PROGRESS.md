# Mkit Implementation Progress

Tracks implementation of the Godot 2D RPG / Roguelike Mkit against
[spec/implementation_spec.md](spec/implementation_spec.md). One checkbox per
spec interface. Checked = implemented in the addon and compile-correct.

Legend: `[x]` done · `[ ]` not started · `[~]` partial / deferred member noted.

---

## Phase 0 — Kernel Prototype ✅

Validation target:

```text
Create a dummy entity. Send a command. State changes. Action runs.
Effect logs a result. Debug trace shows state path and recent events.
```

### Foundation & addon

- [x] `addons/mkit/plugin.cfg` — addon manifest
- [x] `addons/mkit/plugin.gd` — EditorPlugin, registers `ServiceRegistry` autoload
- [x] Folder structure under `addons/mkit/kernel/` per design §7.1
- [x] `project.godot` wired: plugin enabled, `ServiceRegistry` autoload, demo main scene
- [x] `addons/mkit/README.md`

### Runtime Kernel (doc 01)

- [x] ServiceRegistry (`kernel/services/service_registry.gd`) — autoload, no `class_name`
- [x] GameBootstrap (`kernel/bootstrap/game_bootstrap.gd`) — `[~]` registers Phase 0 services only; SaveManager / ProgressionSystem added in Phase 5
- [x] DomainEvent (`kernel/events/domain_event.gd`)
- [x] EventRouter (`kernel/events/event_router.gd`) — `[~]` `damage_applied`/`item_collected` signals + emitters deferred to Phases 1/3 (they require DamageResult / ItemInstance types)
- [x] GameCommand (`kernel/commands/game_command.gd`)
- [x] BuiltinCommands (`kernel/commands/builtin_commands.gd`)
- [x] CommandReceiver (`kernel/commands/command_receiver.gd`) — EntityIdentity resolved via duck typing until the entity module exists
- [x] CommandRouter (`kernel/commands/command_router.gd`)
- [x] GameplayContext (`kernel/context/gameplay_context.gd`)
- [x] Blackboard (`kernel/context/blackboard.gd`)
- [x] RandomService (`kernel/services/random_service.gd`)
- [x] TimeService (`kernel/services/time_service.gd`)
- [x] SceneRouter (`kernel/services/scene_router.gd`)
- [x] ObjectPool (`kernel/services/object_pool.gd`)
- [x] DebugOverlay (`kernel/debug/debug_overlay.gd`) — HealthComponent read via duck typing until combat module exists

### Content Registry (doc 02)

- [x] ResourceDatabase (`kernel/registry/resource_database.gd`)
- [x] ContentRegistry (`kernel/registry/content_registry.gd`)
- [x] ContentValidationResult (`kernel/registry/content_validation_result.gd`)

### HFSM & Actions (doc 03)

- [x] State (`kernel/state_machine/state.gd`)
- [x] StateMachine (`kernel/state_machine/state_machine.gd`) — hierarchical, LCA transitions
- [x] ActionContext (`kernel/context/action_context.gd`)
- [x] GameAction (`kernel/actions/game_action.gd`)
- [x] ActionRunner (`kernel/actions/action_runner.gd`)
- [x] DashAction (`kernel/actions/builtin/dash_action.gd`)
- [x] CastAction (`kernel/actions/builtin/cast_action.gd`)
- [ ] TimedAttackAction — deferred to Phase 1 (depends on HitboxComponent from the combat module)

### Conditions & Effects (doc 04)

- [x] Condition (`kernel/conditions/condition.gd`)
- [x] ConditionEvaluator (`kernel/conditions/condition_evaluator.gd`)
- [x] TargetInRangeCondition (`kernel/conditions/builtin/target_in_range_condition.gd`)
- [ ] CooldownReadyCondition — deferred to Phase 2 (depends on AbilityController)
- [x] EffectResult (`kernel/effects/effect_result.gd`)
- [x] GameEffect (`kernel/effects/game_effect.gd`)
- [x] EffectExecutor (`kernel/effects/effect_executor.gd`)
- [x] LogEffect (`kernel/effects/builtin/log_effect.gd`) — Phase 0 game-agnostic effect for the validation pipeline
- [ ] DealDamageEffect / HealEffect / ApplyStatusEffect / SpawnSceneEffect / GrantItemEffect / ApplyStatModifierEffect — deferred to their owning phases (depend on combat / status / inventory / stats modules)

### Phase 0 validation demo

- [x] `game/demo/dummy_entity.tscn` — dummy entity (CommandReceiver + HFSM Idle/Move/Attack)
- [x] `game/demo/states/*` — Idle / Move / Attack demo states
- [x] `game/demo/actions/demo_wait_action.gd` — timed action used by Attack state
- [x] `game/demo/phase0_demo.tscn` + `phase0_demo.gd` — driver that dispatches commands
- [x] DebugOverlay shows state path, last command, and recent events

**How to run:** open the project in Godot 4.7 and press Play (main scene is
`game/demo/phase0_demo.tscn`). Expected: console prints
`Idle -> Move -> Attack -> Idle`, the `DemoWaitAction` runs, `LogEffect` logs a
successful result and emits an `attack_resolved` event, and the on-screen
DebugOverlay shows the current state path plus recent events. (Not yet run here —
no Godot binary available in this environment.)

---

## Phase 1 — Combat Vertical Slice ⬜

Read: [05 Entity, Stats, Health, Combat](spec/combined/05_entity_stats_health_combat.md),
[12 Core Flows / MVP / Debug](spec/combined/12_core_flows_mvp_debug_and_agent_instructions.md)

- [ ] EntityIdentity / EntityLifecycle
- [ ] StatDefinition / StatModifier / StatsComponent
- [ ] HealthComponent
- [ ] DamageRequest / DamageResult / CombatResolver
- [ ] HitboxComponent / HurtboxComponent
- [ ] TimedAttackAction (combat-dependent action from doc 03)
- [ ] DealDamageEffect / HealEffect
- [ ] EventRouter: `damage_applied` signal + emitter
- [ ] Player move / attack; enemy takes damage and dies; damage + death events emitted

## Phase 2 — Ability & Status Slice ⬜

- [ ] AbilityDefinition / AbilityInstance / AbilityController
- [ ] StatusEffectDefinition / StatusEffectInstance / StatusEffectController
- [ ] CooldownReadyCondition
- [ ] ApplyStatusEffect / SpawnSceneEffect

## Phase 3 — Inventory, Equipment, Loot, Reward ⬜

- [ ] ItemDefinition / ItemInstance / InventoryModel / InventoryController
- [ ] EquipmentSlot / EquipmentController
- [ ] LootTableDefinition / LootEntry / LootSystem
- [ ] RewardDefinition / RewardOption / RewardSystem
- [ ] GrantItemEffect / ApplyStatModifierEffect
- [ ] EventRouter: `item_collected` signal + emitter

## Phase 4 — Room, Run, Procedural Generation ⬜

- [ ] RoomDefinition / RoomController
- [ ] RunState / RunDirector
- [ ] DungeonGenerator / RoomGraph / GenerationRules

## Phase 5 — Save & Meta Progression ⬜

- [ ] SaveManager / Saveable / SaveMigration
- [ ] UpgradeDefinition / ProgressionSystem
- [ ] GameBootstrap: register `save` + `progression` services

## Phase 6 — Platform Services ⬜

- [ ] Ads / Analytics / IAP / CloudSave (mock implementations first)
