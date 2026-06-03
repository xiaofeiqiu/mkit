# Pipeline

管线是一个玩法请求从入口到结果的固定执行路径。它描述“谁发起、经过哪些系统、产生什么状态变化、最后由谁响应”，用于把复杂玩法拆成可追踪、可测试、可替换的步骤。

在 Mkit 中，管线通常从输入、AI、脚本、UI 或系统事件开始，经过 Kernel 的命令、状态机、Action、Condition、Effect、服务和事件机制，再落到 Module Layer 的战斗、背包、房间、奖励、进度等领域系统，最后通知 UI、音效、VFX、Analytics 或 Debug。每个 section 表示一条独立管线。

## Runtime Bootstrap Pipeline

主要类：[GameBootstrap](ref/GameBootstrap.md), [ServiceRegistry](ref/ServiceRegistry.md), [ContentRegistry](ref/ContentRegistry.md), [SceneRouter](ref/SceneRouter.md)

```text
Bootstrap scene
  -> GameBootstrap.boot()
  -> register kernel services into ServiceRegistry
  -> load resource databases
  -> validate content
  -> initialize runtime systems
  -> load profile
  -> enter initial scene
```

## Content Load & Validation Pipeline

主要类：[ContentRegistry](ref/ContentRegistry.md), [ResourceDatabase](ref/ResourceDatabase.md), [ContentValidationResult](ref/ContentValidationResult.md)

```text
ResourceDatabase list
  -> ContentRegistry.load_database()
  -> register_resource()
  -> extract stable content id
  -> index by id/type
  -> validate_all()
  -> ContentValidationResult errors/warnings
```

## Service Lookup Pipeline

主要类：[ServiceRegistry](ref/ServiceRegistry.md)

```text
System needs shared service
  -> ServiceRegistry.has_service(service_id)
  -> ServiceRegistry.get_service(service_id)
  -> call public API on service
  -> service emits signal or returns result
```

## Main Gameplay Pipeline

主要类：[GameCommand](ref/GameCommand.md), [CommandRouter](ref/CommandRouter.md), [CommandReceiver](ref/CommandReceiver.md), [StateMachine](ref/StateMachine.md), [ActionRunner](ref/ActionRunner.md), [EffectExecutor](ref/EffectExecutor.md), [EventRouter](ref/EventRouter.md)

```text
Input / AI / Script
  -> GameCommand
  -> CommandRouter.dispatch()
  -> CommandReceiver.receive_command()
  -> StateMachine.handle_command() / transition_to()
  -> ActionRunner.start_action() optional
  -> EffectExecutor.execute_many() optional
  -> Domain modules
  -> EventRouter.emit_*
  -> HUD / VFX / Audio / Analytics listeners
```

## Command Dispatch Pipeline

主要类：[GameCommand](ref/GameCommand.md), [BuiltinCommands](ref/BuiltinCommands.md), [CommandRouter](ref/CommandRouter.md), [CommandReceiver](ref/CommandReceiver.md)

```text
Command source creates GameCommand
  -> set command_type/source_id/target_id/payload
  -> CommandRouter.dispatch(command)
  -> lookup receiver by target_id
  -> CommandReceiver.receive_command(command)
  -> owner StateMachine handles command
```

## Event Notification Pipeline

主要类：[DomainEvent](ref/DomainEvent.md), [EventRouter](ref/EventRouter.md), [FeedbackSystem](ref/FeedbackSystem.md), [DebugOverlay](ref/DebugOverlay.md)

```text
Domain fact occurs
  -> create typed event or emit_* helper
  -> EventRouter emits signal
  -> recent_events records trace
  -> UI / Feedback / Analytics / Debug listeners react
```

## HFSM Transition Pipeline

主要类：[StateMachine](ref/StateMachine.md), [State](ref/State.md), [CommandReceiver](ref/CommandReceiver.md)

```text
StateMachine receives command or explicit transition
  -> find current leaf state
  -> validate can_exit chain
  -> validate can_enter chain
  -> find lowest common ancestor
  -> exit old branch
  -> enter new branch
  -> enter initial children
  -> update current leaf state
```

## Action Lifecycle Pipeline

主要类：[GameAction](ref/GameAction.md), [ActionContext](ref/ActionContext.md), [ActionRunner](ref/ActionRunner.md), [TimedAttackAction](ref/TimedAttackAction.md), [DashAction](ref/DashAction.md), [CastAction](ref/CastAction.md)

```text
State or controller creates GameAction
  -> build ActionContext
  -> ActionRunner.start_action()
  -> GameAction.start()
  -> ActionRunner updates with scaled delta
  -> GameAction.complete() or cancel()
  -> action_completed/action_cancelled signal
  -> StateMachine or controller continues flow
```

## Time Scaling & Pause Pipeline

主要类：[TimeService](ref/TimeService.md), [ActionRunner](ref/ActionRunner.md), [UIManager](ref/UIManager.md)

```text
Gameplay pause or time scale changes
  -> TimeService.set_paused() / set_gameplay_time_scale()
  -> ActionRunner reads TimeService.get_scaled_delta()
  -> actions advance, slow down, or stop
  -> modal UI can pause gameplay through UIManager
```

## Condition Evaluation Pipeline

主要类：[Condition](ref/Condition.md), [ConditionEvaluator](ref/ConditionEvaluator.md), [CooldownReadyCondition](ref/CooldownReadyCondition.md), [TargetInRangeCondition](ref/TargetInRangeCondition.md), [GameplayContext](ref/GameplayContext.md)

```text
Ability / reward / loot entry has conditions
  -> build GameplayContext
  -> ConditionEvaluator.evaluate_all()
  -> each Condition.evaluate(context)
  -> builtin condition reads context/services/components
  -> caller includes or rejects candidate
```

## Effect Execution Pipeline

主要类：[GameEffect](ref/GameEffect.md), [EffectExecutor](ref/EffectExecutor.md), [EffectResult](ref/EffectResult.md), [GameplayContext](ref/GameplayContext.md)

```text
System has one or more effects
  -> build GameplayContext
  -> EffectExecutor.execute_many(effects, context)
  -> each GameEffect.apply(context)
  -> collect EffectResult
  -> stop_on_failure optional
  -> record trace for debug
```

## Scene Spawn Pipeline

主要类：[SpawnSceneEffect](ref/SpawnSceneEffect.md), [GameplayContext](ref/GameplayContext.md)

```text
SpawnSceneEffect.apply(context)
  -> load PackedScene and instantiate
  -> add to SceneTree.current_scene
  -> initialize Node2D position from target/source/context
  -> call set_direction(context.direction) when available
  -> return EffectResult
```

## Object Pool Pipeline

主要类：[ObjectPool](ref/ObjectPool.md)

```text
System requests pooled scene instance
  -> ObjectPool.acquire(scene_path, parent)
  -> reuse inactive node or load PackedScene and instantiate
  -> activate node and call on_pool_acquired() if available
  -> caller uses node
  -> ObjectPool.release(scene_path, node)
  -> deactivate node and call on_pool_released() if available
```

## Entity Spawn Pipeline

主要类：[EntitySpawner](ref/EntitySpawner.md), [EntityDefinition](ref/EntityDefinition.md), [EntityIdentity](ref/EntityIdentity.md), [StatsComponent](ref/StatsComponent.md), [AbilityController](ref/AbilityController.md)

```text
Room or script requests entity definition id
  -> EntitySpawner.spawn_entity()
  -> ContentRegistry returns EntityDefinition
  -> load definition.scene_path
  -> instantiate scene under parent
  -> initialize EntityIdentity
  -> initialize base StatsComponent values
  -> register starting abilities
  -> entity_spawned signal
```

## Stats & Modifier Pipeline

主要类：[StatsComponent](ref/StatsComponent.md), [StatDefinition](ref/StatDefinition.md), [StatModifierDefinition](ref/StatModifierDefinition.md), [StatModifier](ref/StatModifier.md), [ApplyStatModifierEffect](ref/ApplyStatModifierEffect.md)

```text
Base stat or modifier changes
  -> StatsComponent.set_base_stat() / add_modifier()
  -> apply stacking/source rules
  -> calculate final stat value
  -> emit stat_changed
  -> dependent components read updated value
```

## Resource Spend & Restore Pipeline

主要类：[ResourcePoolComponent](ref/ResourcePoolComponent.md), [StatsComponent](ref/StatsComponent.md), [AbilityController](ref/AbilityController.md)

```text
Ability or system needs mana/stamina/etc.
  -> ResourcePoolComponent.has_resource()
  -> spend() or restore()
  -> clamp current value by max_<resource> stat
  -> emit resource_changed/resource_spent/resource_restored
  -> UI or gameplay listeners update
```

## Attack & Hitbox Pipeline

主要类：[TimedAttackAction](ref/TimedAttackAction.md), [HitboxComponent](ref/HitboxComponent.md), [HurtboxComponent](ref/HurtboxComponent.md), [DamageRequest](ref/DamageRequest.md), [CombatResolver](ref/CombatResolver.md), [HealthComponent](ref/HealthComponent.md)

```text
Attack command
  -> StateMachine enters attack state
  -> TimedAttackAction starts
  -> active frames enable HitboxComponent
  -> Hitbox detects Hurtbox
  -> validate faction / hit-once rule
  -> create DamageRequest
  -> CombatResolver.resolve()
  -> HealthComponent.apply_damage()
  -> events and feedback
```

## Ability Cast Pipeline

主要类：[AbilityController](ref/AbilityController.md), [AbilityDefinition](ref/AbilityDefinition.md), [AbilityInstance](ref/AbilityInstance.md), [CastAction](ref/CastAction.md), [ConditionEvaluator](ref/ConditionEvaluator.md), [EffectExecutor](ref/EffectExecutor.md)

```text
CAST_ABILITY command
  -> StateMachine enters cast state
  -> AbilityController.can_cast()
  -> check cooldown/cost/conditions
  -> pay resource cost
  -> start CastAction if cast_time > 0
  -> execute ability effects
  -> start cooldown
  -> emit ability/cooldown signals
```

## Status Effect Pipeline

主要类：[StatusEffectController](ref/StatusEffectController.md), [StatusEffectDefinition](ref/StatusEffectDefinition.md), [StatusEffectInstance](ref/StatusEffectInstance.md), [ApplyStatusEffect](ref/ApplyStatusEffect.md), [EffectExecutor](ref/EffectExecutor.md)

```text
ApplyStatusEffect or system requests status
  -> StatusEffectController.apply_status()
  -> load StatusEffectDefinition
  -> create instance or apply stack rule
  -> apply stat modifiers
  -> execute effects_on_apply
  -> process duration/tick timers
  -> execute effects_on_tick
  -> remove expired status
  -> execute effects_on_remove and remove modifiers
```

## Damage Resolution Pipeline

主要类：[DealDamageEffect](ref/DealDamageEffect.md), [DamageRequest](ref/DamageRequest.md), [CombatResolver](ref/CombatResolver.md), [DamageResult](ref/DamageResult.md), [HealthComponent](ref/HealthComponent.md)

```text
Damage source creates DamageRequest
  -> CombatResolver reads source/target stats
  -> apply attack/defense/crit/element/status rules
  -> produce DamageResult
  -> HealthComponent.apply_damage(result)
  -> emit damage_applied
  -> lethal result continues into Death Pipeline
```

## Healing Pipeline

主要类：[HealEffect](ref/HealEffect.md), [HealthComponent](ref/HealthComponent.md), [StatsComponent](ref/StatsComponent.md), [EventRouter](ref/EventRouter.md)

```text
HealEffect or system requests healing
  -> calculate amount and optional healing multiplier
  -> HealthComponent.heal()
  -> clamp to max HP
  -> emit healed / health changed event
  -> UI and feedback listeners update
```

## Death Pipeline

主要类：[HealthComponent](ref/HealthComponent.md), [EventRouter](ref/EventRouter.md), [RoomController](ref/RoomController.md), [RunDirector](ref/RunDirector.md), [FeedbackSystem](ref/FeedbackSystem.md)

```text
DamageResult is lethal
  -> HealthComponent reaches 0 HP
  -> emit entity_died
  -> RoomController updates enemy count for non-player deaths
  -> RunDirector fails run for player death
  -> Loot/Reward/Room pipelines may continue
  -> VFX / Audio / UI / Analytics react
```

## Quest Pipeline

主要类：[QuestSystem](ref/QuestSystem.md), [QuestDefinition](ref/QuestDefinition.md), [QuestObjectiveDefinition](ref/QuestObjectiveDefinition.md), [QuestState](ref/QuestState.md), [QuestLog](ref/QuestLog.md), [AcceptQuestEffect](ref/AcceptQuestEffect.md), [AdvanceObjectiveEffect](ref/AdvanceObjectiveEffect.md), [CompleteQuestEffect](ref/CompleteQuestEffect.md), [EventRouter](ref/EventRouter.md), [EffectExecutor](ref/EffectExecutor.md)

```text
Dialogue / interaction / script / UI accepts quest
  -> AcceptQuestEffect or QuestSystem.accept_quest()
  -> QuestState becomes active
  -> EventRouter emits quest_accepted
  -> gameplay systems emit DomainEvent facts
  -> entity_died signal bridges to enemy_killed
  -> inventory_changed with added payload bridges to item_acquired
  -> QuestSystem.notify_event() matches QuestObjectiveDefinition
  -> objective progress advances
  -> all required objectives complete
  -> CompleteQuestEffect or QuestSystem.complete_quest()
  -> turn_in executes reward_effects through EffectExecutor and stops on failure
  -> EventRouter emits quest_completed / quest_turned_in
  -> QuestLog persists through SaveManager
```

## Enemy AI Pipeline

主要类：[Brain](ref/Brain.md), [SimpleAIEnemyBrain](ref/SimpleAIEnemyBrain.md), [GameCommand](ref/GameCommand.md), [CommandRouter](ref/CommandRouter.md)

```text
Brain process tick
  -> think() evaluates target/distance/state
  -> issue move/attack/cast/stop command
  -> CommandRouter.dispatch()
  -> CommandReceiver and StateMachine handle command
  -> normal action/combat pipeline continues
```

## Interaction Pipeline

主要类：[InteractionComponent](ref/InteractionComponent.md), [Interactable](ref/Interactable.md), [GameplayContext](ref/GameplayContext.md)

```text
Interactor enters interaction area
  -> InteractionComponent tracks nearby Interactable
  -> player/script triggers interact
  -> build GameplayContext
  -> Interactable.interact(context)
  -> concrete interactable executes effects or domain action
  -> events/UI/feedback react
```

## Inventory Add & Remove Pipeline

主要类：[InventoryController](ref/InventoryController.md), [InventoryModel](ref/InventoryModel.md), [InventorySlot](ref/InventorySlot.md), [ItemDefinition](ref/ItemDefinition.md), [ItemInstance](ref/ItemInstance.md), [EventRouter](ref/EventRouter.md)

```text
ItemInstance enters inventory flow
  -> InventoryController.can_add_item()
  -> load ItemDefinition
  -> stack into compatible slot if possible
  -> otherwise place into empty slot
  -> remove flow updates quantity or clears slot
  -> emit inventory_changed / item_added / item_removed
  -> UI and analytics listeners react
```

## Item Pickup Pipeline

主要类：[InventoryController](ref/InventoryController.md), [ItemInstance](ref/ItemInstance.md), [GrantItemEffect](ref/GrantItemEffect.md), [EventRouter](ref/EventRouter.md)

```text
Player overlaps or accepts pickup
  -> pickup creates ItemInstance or GrantItemEffect
  -> InventoryController.can_add_item()
  -> InventoryController.add_item()
  -> inventory_changed event
  -> pickup node consumed or remains if add failed
  -> UI / Audio / Analytics react
```

## Equipment Pipeline

主要类：[EquipmentController](ref/EquipmentController.md), [InventoryController](ref/InventoryController.md), [ItemDefinition](ref/ItemDefinition.md), [ItemInstance](ref/ItemInstance.md), [StatsComponent](ref/StatsComponent.md)

```text
UI or script requests equip
  -> EquipmentController.can_equip(item, slot)
  -> remove old item modifiers if replacing
  -> set equipped item
  -> apply item stat modifiers and rolled affixes
  -> emit equipment_changed
  -> unequip reverses modifiers and returns item to inventory flow
```

## Shop Pipeline

主要类：[ShopController](ref/ShopController.md), [ShopDefinition](ref/ShopDefinition.md), [ShopEntry](ref/ShopEntry.md), [InventoryController](ref/InventoryController.md), [ProgressionSystem](ref/ProgressionSystem.md), [ItemInstance](ref/ItemInstance.md), [EventRouter](ref/EventRouter.md)

```text
Player opens shop
  -> ShopController.open_shop(shop_id)
  -> ContentRegistry returns ShopDefinition
  -> emit shop_opened
  -> buy() checks ShopEntry conditions/stock/inventory space/currency
  -> ProgressionSystem.spend_currency()
  -> InventoryController.add_item()
  -> rollback currency if inventory rejects item
  -> decrement ShopEntry stock
  -> emit item_purchased / EventRouter.emit_item_purchased
  -> sell() locates instance, removes from inventory, adds currency
  -> emit item_sold / EventRouter.emit_item_sold
  -> transaction_failed on any rejection
```

## Loot Roll Pipeline

主要类：[LootSystem](ref/LootSystem.md), [LootTableDefinition](ref/LootTableDefinition.md), [LootEntry](ref/LootEntry.md), [LootRollResult](ref/LootRollResult.md), [ConditionEvaluator](ref/ConditionEvaluator.md), [RandomService](ref/RandomService.md)

```text
Enemy/chest/system requests loot table
  -> LootSystem.roll_table(table_id, context)
  -> ContentRegistry returns LootTableDefinition
  -> filter LootEntry by conditions
  -> roll weighted entries with RandomService
  -> create ItemInstance/currency result
  -> return LootRollResult
  -> caller decides pickup, chest UI, or direct inventory add
```

## Reward Selection Pipeline

主要类：[RewardSystem](ref/RewardSystem.md), [RewardDefinition](ref/RewardDefinition.md), [RewardOption](ref/RewardOption.md), [RewardSelectionUI](ref/RewardSelectionUI.md), [EffectExecutor](ref/EffectExecutor.md)

```text
Room/run requests reward options
  -> RewardSystem.generate_options(pool_ids, count, context)
  -> filter RewardDefinition by conditions
  -> weighted pick options
  -> UIManager opens RewardSelectionUI
  -> player selects RewardOption
  -> RewardSystem.apply_selected()
  -> EffectExecutor executes option effects
  -> emit reward_selected
  -> RunDirector advances
```

## Room Lifecycle Pipeline

主要类：[RoomController](ref/RoomController.md), [RoomDefinition](ref/RoomDefinition.md), [RoomRuntime](ref/RoomRuntime.md), [EntitySpawner](ref/EntitySpawner.md), [RewardSystem](ref/RewardSystem.md)

```text
RunDirector loads room
  -> RoomController.setup(room_definition_id)
  -> enter_room()
  -> spawn_enemies()
  -> listen for entity_died
  -> update active_enemy_ids
  -> check_clear_condition()
  -> generate_reward()
  -> emit reward_ready
  -> emit room_cleared
```

## Run Lifecycle Pipeline

主要类：[RunDirector](ref/RunDirector.md), [RunState](ref/RunState.md), [RoomGraph](ref/RoomGraph.md), [RoomNode](ref/RoomNode.md), [DungeonGenerator](ref/DungeonGenerator.md), [RewardSystem](ref/RewardSystem.md)

```text
Start run request
  -> RunDirector.start_run(seed)
  -> create RunState
  -> set RandomService seed
  -> DungeonGenerator creates RoomGraph
  -> enter_next_room()
  -> Room Lifecycle Pipeline
  -> choose reward after clear
  -> select_reward()
  -> advance room index
  -> complete_run() or fail_run()
```

## Dungeon Generation Pipeline

主要类：[DungeonGenerator](ref/DungeonGenerator.md), [RoomGraph](ref/RoomGraph.md), [RoomNode](ref/RoomNode.md), [RandomService](ref/RandomService.md)

```text
RunDirector supplies room pool and seed
  -> DungeonGenerator.generate_linear()
  -> choose ordered room ids
  -> create RoomNode entries
  -> append nodes to RoomGraph
  -> RunDirector reads graph by current_room_index
```

## Experience & Level Up Pipeline

主要类：[ExperienceComponent](ref/ExperienceComponent.md), [ExperienceCurve](ref/ExperienceCurve.md), [Saveable](ref/Saveable.md)

```text
System grants XP
  -> ExperienceComponent.add_xp(amount)
  -> compare current_xp with ExperienceCurve requirement
  -> loop level ups while enough XP
  -> emit level_up for each level
  -> emit xp_changed
  -> SaveManager can persist component state
```

## Meta Progression & Upgrade Pipeline

主要类：[ProgressionSystem](ref/ProgressionSystem.md), [ProgressionState](ref/ProgressionState.md), [UpgradeDefinition](ref/UpgradeDefinition.md), [EffectExecutor](ref/EffectExecutor.md), [Saveable](ref/Saveable.md)

```text
Run reward or UI grants currency
  -> ProgressionSystem.add_currency()
  -> UI requests can_unlock(upgrade_id)
  -> load UpgradeDefinition
  -> check level, prerequisites, currency cost
  -> spend currency
  -> update ProgressionState level
  -> unlock content ids
  -> execute upgrade effects
  -> emit currency/upgrade/unlock signals
  -> SaveManager persists state
```

## Save Pipeline

主要类：[SaveManager](ref/SaveManager.md), [Saveable](ref/Saveable.md), [RunState](ref/RunState.md), [ProgressionSystem](ref/ProgressionSystem.md), [ExperienceComponent](ref/ExperienceComponent.md)

```text
Save requested
  -> SaveManager.save_game(root)
  -> collect Saveable nodes
  -> call to_save_data()
  -> include save_version and payload
  -> serialize to storage
  -> optional cloud sync through CloudSaveService
```

## Load & Migration Pipeline

主要类：[SaveManager](ref/SaveManager.md), [SaveMigration](ref/SaveMigration.md), [Saveable](ref/Saveable.md)

```text
Load requested
  -> SaveManager.load_game(root)
  -> read serialized data
  -> compare save_version
  -> apply SaveMigration chain if needed
  -> collect Saveable nodes
  -> route payload by save_id
  -> call from_save_data()
  -> systems emit restored state updates
```

## Scene Routing Pipeline

主要类：[SceneRouter](ref/SceneRouter.md), [ServiceRegistry](ref/ServiceRegistry.md)

```text
System requests scene change
  -> SceneRouter.change_scene(scene_path)
  -> reject empty path or transition lock
  -> emit scene_change_requested
  -> get_tree().change_scene_to_file()
  -> emit scene_changed or scene_change_failed
```

## World Navigation Pipeline

主要类：[WorldRouter](ref/WorldRouter.md), [ZoneDefinition](ref/ZoneDefinition.md), [Portal](ref/Portal.md), [SpawnPoint](ref/SpawnPoint.md), [SceneRouter](ref/SceneRouter.md), [EventRouter](ref/EventRouter.md), [AudioManager](ref/AudioManager.md)

```text
Portal interaction or script requests zone change
  -> Portal._interact_impl() gets world service
  -> WorldRouter.go_to_zone(zone_id, spawn_id)
  -> ContentRegistry returns ZoneDefinition
  -> record pending zone/spawn, fallback to default_spawn_id
  -> SceneRouter.change_scene(scene_path)
  -> scene_changed callback finalizes deferred
  -> place_player_at_spawn() moves persistent player to matching SpawnPoint
  -> update current_zone_id
  -> emit zone_changed / EventRouter.emit_zone_changed
  -> emit zone_entered DomainEvent advances quest objectives
  -> AudioManager.play_music(zone bgm_id)
```

## UI Screen Pipeline

主要类：[UIManager](ref/UIManager.md), [RewardSelectionUI](ref/RewardSelectionUI.md), [TimeService](ref/TimeService.md)

```text
Gameplay requests screen
  -> UIManager.open_screen(screen_id, data, modal)
  -> load screen scene from screen_scene_map
  -> instantiate under screen root
  -> call setup(data) if available
  -> push screen stack
  -> pause gameplay for modal screen
  -> close_screen() resumes gameplay when no modal remains
```

## Feedback Pipeline

主要类：[FeedbackSystem](ref/FeedbackSystem.md), [DamageNumberSystem](ref/DamageNumberSystem.md), [VFXSpawner](ref/VFXSpawner.md), [AudioManager](ref/AudioManager.md), [EventRouter](ref/EventRouter.md)

```text
EventRouter emits damage_applied or entity_died
  -> FeedbackSystem listener receives event
  -> DamageNumberSystem.show_number()
  -> VFXSpawner.spawn()
  -> AudioManager.play_sfx()
  -> visual/audio feedback stays decoupled from combat
```

## Analytics Pipeline

主要类：[AnalyticsService](ref/AnalyticsService.md), [AnalyticsServiceMock](ref/AnalyticsServiceMock.md), [ServiceRegistry](ref/ServiceRegistry.md)

```text
Gameplay fact should be tracked
  -> system gets analytics service
  -> AnalyticsService.track_event(event_name, properties)
  -> mock prints/stores event in editor
  -> real adapter can forward to SDK
  -> gameplay does not depend on SDK
```

## Rewarded Ad Pipeline

主要类：[AdService](ref/AdService.md), [AdServiceMock](ref/AdServiceMock.md), [HealthComponent](ref/HealthComponent.md)

```text
Gameplay/UI offers rewarded action
  -> AdService.is_rewarded_ad_ready(placement_id)
  -> connect completed/failed signals
  -> AdService.show_rewarded_ad(placement_id)
  -> rewarded_ad_completed grants revive/reward
  -> rewarded_ad_failed returns to fallback flow
```

## IAP Pipeline

主要类：[IAPService](ref/IAPService.md), [IAPServiceMock](ref/IAPServiceMock.md), [ProgressionSystem](ref/ProgressionSystem.md)

```text
Store UI opens
  -> IAPService.load_products(product_ids)
  -> products_loaded updates UI
  -> purchase(product_id)
  -> purchase_completed grants entitlement/currency
  -> purchase_failed shows failure state
  -> restore_purchases() restores owned product ids
```

## Cloud Save Pipeline

主要类：[CloudSaveService](ref/CloudSaveService.md), [CloudSaveServiceMock](ref/CloudSaveServiceMock.md), [SaveManager](ref/SaveManager.md)

```text
Local save data is ready
  -> CloudSaveService.is_available()
  -> save_to_cloud(slot, data)
  -> cloud_save_completed or cloud_save_failed
  -> load_from_cloud(slot)
  -> cloud_load_completed supplies Dictionary
  -> SaveManager load/migration pipeline restores state
```

## Debug Overlay Pipeline

主要类：[DebugOverlay](ref/DebugOverlay.md), [EventRouter](ref/EventRouter.md), [StateMachine](ref/StateMachine.md), [HealthComponent](ref/HealthComponent.md)

```text
DebugOverlay watches target entity
  -> read StateMachine current state path
  -> read HealthComponent values
  -> read latest command/debug fields
  -> read EventRouter recent events
  -> render runtime debug text
```

## Integration Coverage

Integration coverage ownership is tracked in `spec/int-test.md` under `Full coverage verification ledger`. Any change that adds, removes, renames, or splits a `## ... Pipeline` section in this document must update that ledger and the affected suggested integration test file section in the same change.
