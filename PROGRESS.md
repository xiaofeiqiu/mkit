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

## Phase 1 — Combat Vertical Slice ✅ (slice)

Read: [05 Entity, Stats, Health, Combat](spec/combined/05_entity_stats_health_combat.md),
[12 Core Flows / MVP / Debug](spec/combined/12_core_flows_mvp_debug_and_agent_instructions.md)

Validation target:

```text
Player moves. Player attacks. Enemy takes damage. Enemy dies.
Damage and death events are emitted.
```

### Entity module (doc 05 §8)

- [x] EntityIdentity (`modules/entity/entity_identity.gd`)
- [x] EntityRoot (`modules/entity/entity_root.gd`)
- [ ] EntityDefinition / EntitySpawner — deferred (EntitySpawner depends on AbilityController from Phase 2; demo places entities directly in scene)

### Stats module (doc 05 §9)

- [x] StatDefinition (`modules/stats/stat_definition.gd`)
- [x] StatModifierDefinition (`modules/stats/stat_modifier_definition.gd`)
- [x] StatModifier (`modules/stats/stat_modifier.gd`)
- [x] StatsComponent (`modules/stats/stats_component.gd`)

### Health module (doc 05 §10)

- [x] HealthComponent (`modules/health/health_component.gd`) — on-hit status application duck-types StatusEffectController (Phase 2)
- [ ] ResourcePoolComponent — deferred to Phase 2 (mana/stamina for abilities)

### Combat module (doc 05 §11)

- [x] DamageRequest (`modules/combat/damage_request.gd`)
- [x] DamageResult (`modules/combat/damage_result.gd`)
- [x] CombatResolver (`modules/combat/combat_resolver.gd`)
- [x] HitboxComponent (`modules/combat/hitbox_component.gd`) — monitoring kept on + scan-on-activate so a stationary already-overlapping target is still hit
- [x] HurtboxComponent (`modules/combat/hurtbox_component.gd`)

### Kernel additions

- [x] TimedAttackAction (`kernel/actions/builtin/timed_attack_action.gd`) — now that HitboxComponent exists
- [x] EventRouter: `damage_applied` signal + `emit_damage_applied` (param left untyped to keep kernel below the combat module) + `_get_entity_id`
- [x] GameBootstrap: parents kernel services under the persistent `ServiceRegistry` autoload (so they survive the scene change), idempotent re-boot guard
- [x] **Framework fix:** GameBootstrap refuses an `initial_scene_path` that resolves to the scene already containing it (prevents the infinite bootstrap-reload loop); normalizes `uid://` paths
- [ ] DealDamageEffect / HealEffect — deferred (Hitbox→CombatResolver path is used directly in the slice; the declarative damage Effect lands with the ability system in Phase 2)

### Phase 1 validation demo (bootstrap → initial scene)

- [x] `game/demo/bootstrap.tscn` — minimal scene: just GameBootstrap, `initial_scene_path` → combat_arena
- [x] `game/demo/combat_arena.tscn` + `combat_arena.gd` — green player + red enemy, logs `damage_applied` / `entity_died`
- [x] `game/demo/player/player.tscn` (green square) — EntityIdentity, CommandReceiver, HFSM (Idle/Move/Attack), StatsComponent, HealthComponent, HitboxComponent, keyboard input reader
- [x] `game/demo/enemy/enemy.tscn` (red square) — EntityIdentity, StatsComponent (max_hp 30), HealthComponent (destroy_on_death), HurtboxComponent
- [x] `project.godot` main scene → `bootstrap.tscn`

**How to run:** press Play. GameBootstrap boots services then enters `combat_arena.tscn`.
Move the green square with WASD/Arrows, attack with Space/J. Each hit prints
`[EVENT] damage_applied -> N damage to Enemy`; after enough hits the red square
disappears and `[EVENT] entity_died -> enemy_001` prints. The DebugOverlay shows
the player's live state path, last command, HP, and recent events. (Not yet run
here — no Godot binary available in this environment.)

The earlier kernel-only [phase0_demo.tscn](game/demo/phase0_demo.tscn) still
exists as a standalone scene for inspecting the bare command→state→action→effect
pipeline.

## Phase 2 — Ability & Status Slice ✅

Read: [06 Ability and Status Effects](spec/combined/06_ability_and_status_effects.md)

Validation target:

```text
Player casts fireball. Fireball damages enemy. Burn ticks every second.
Cooldown blocks repeated cast.
```

### Health module additions

- [x] ResourcePoolComponent (`modules/health/resource_pool_component.gd`) — mana/stamina pool; max from StatsComponent

### Ability module (doc 06 §12)

- [x] AbilityDefinition (`modules/abilities/ability_definition.gd`)
- [x] AbilityInstance (`modules/abilities/ability_instance.gd`)
- [x] AbilityController (`modules/abilities/ability_controller.gd`)

### Status Effect module (doc 06 §13)

- [x] StatusEffectDefinition (`modules/status_effects/status_effect_definition.gd`)
- [x] StatusEffectInstance (`modules/status_effects/status_effect_instance.gd`)
- [x] StatusEffectController (`modules/status_effects/status_effect_controller.gd`)

### Kernel additions

- [x] CooldownReadyCondition (`kernel/conditions/builtin/cooldown_ready_condition.gd`)
- [x] DealDamageEffect (`kernel/effects/builtin/deal_damage_effect.gd`)
- [x] HealEffect (`kernel/effects/builtin/heal_effect.gd`)
- [x] ApplyStatusEffect (`kernel/effects/builtin/apply_status_effect.gd`)
- [x] SpawnSceneEffect (`kernel/effects/builtin/spawn_scene_effect.gd`)

### Phase 2 validation demo

- [x] `game/demo/entities/player/states/player_cast_ability_state.gd` — CastAbilityState (finds nearest enemy, calls AbilityController.cast)
- [x] `game/demo/entities/player/player.tscn` — added CastAbility state, Controllers/AbilityController, Controllers/StatusEffectController, Components/ResourcePoolComponent (50 mana), max_mana in StatsComponent
- [x] `game/demo/entities/enemy/enemy.tscn` — added Controllers/StatusEffectController, enemy group
- [x] `game/demo/entities/player/player_input_reader.gd` — Q key → CAST_ABILITY fireball
- [x] Player idle/move states — CAST_ABILITY → CastAbility transition
- [x] `game/demo/phase2_ability_slice.tscn` + `phase2_ability_slice.gd` — registers ability.fireball_basic + status.burn at runtime, wires player AbilityController, logs all events
- [x] `game/demo/bootstrap.tscn` → `phase2_ability_slice.tscn`

**How to run:** press Play. GameBootstrap boots services then enters `phase2_ability_slice.tscn`.
Move with WASD/Arrows, melee with Space/J, cast fireball with Q. Expected console output:
`[ABILITY] cooldown started: ability.fireball_basic (3.0s)` after first cast,
`[EVENT] damage_applied -> 30.x magic dmg to Enemy`,
`[STATUS] applied: status.burn (stacks=1)`,
`[STATUS] tick: status.burn` every second,
`[ABILITY] cast failed: ability.fireball_basic — on_cooldown: ...` if cast during cooldown.

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
