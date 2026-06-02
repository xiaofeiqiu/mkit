# Mkit Integration Test Design

## 目标

本设计用于规划 `test/integration/` 下的 GUT integration tests。测试目标不是重复 unit test，而是验证 `docs/readme.md` 和 `docs/pipeline.md` 描述的跨层运行管线可以在同一棵 scene tree、同一套 `ServiceRegistry` 服务和同一批 data-driven `Resource` 下协同工作。

Integration test 只覆盖 reusable runtime 机制，不在 `addons/mkit/` 中写入具体游戏内容。测试里的 item、ability、room、reward、entity id 都是临时测试数据，放在 test helper 或临时 resource 中。

## 范围

测试放置：

```text
test/integration/
```

设计文档：

```text
spec/int-test.md
```

建议入口：

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/integration -gexit
```

后续可按需在 `Makefile` 增加 `it` 或 `integration` 目标，但本设计阶段不修改命令入口。

## 测试原则

- 使用真实 `GameBootstrap`、`ServiceRegistry`、`ContentRegistry`、`CommandRouter`、`EventRouter`、`ActionRunner`、`EffectExecutor` 和 module controllers。
- 使用临时 `ResourceDatabase` 和内存构造的 definitions，避免依赖 `game/demo/` 的具体内容。
- 需要 scene path 的管线使用测试期间临时保存的 `PackedScene`，路径放在可控测试目录或临时目录。
- 所有随机行为注入 deterministic `RandomService` subclass。
- 每个 test `after_each()` 清理 `ServiceRegistry`，释放临时 scene/resource，避免跨测试污染。
- Integration case 按 pipeline 粒度设计，多个 pipeline 可以合并在同一个端到端场景中验证，但 `spec` 必须明确它覆盖了哪些 pipeline。

## Fixture 设计

### TestContentBuilder

负责构造临时 `ResourceDatabase`：

- `ItemDefinition`
- `AbilityDefinition`
- `EntityDefinition`
- `LootTableDefinition`
- `RewardDefinition`
- `RoomDefinition`
- `UpgradeDefinition`
- `StatusEffectDefinition`
- `StatDefinition`

同时提供一个专门 helper 保存临时 `.tres`：

- 构造一个带稳定 id 的 `Resource`，例如 `ItemDefinition.item_id = "int_test_item_path"`。
- 使用 `ResourceSaver.save(resource, "user://mkit_int_test_item.tres")` 或测试可清理路径写出 `.tres`。
- 把该路径放入 `ResourceDatabase.resource_paths`。
- 通过 `ContentRegistry.load_database()` 验证 `ResourceDatabase.get_all_resources()` 真实走到 `load(path)`。

内存 resource 和 `.tres` path 两条路径都要测。前者覆盖测试构造便利性，后者覆盖 Godot resource serialization、path loading 和项目真实内容注册方式。

### TestSceneBuilder

负责构造最小 scene tree：

```text
TestRoot
  Bootstrap
  World
    Player
      EntityIdentity
      StateMachine
      CommandReceiver
      Components/
        StatsComponent
        HealthComponent
        ResourcePoolComponent
      Controllers/
        AbilityController
        StatusEffectController
        InventoryController
        EquipmentController
    Enemies/
    EntitySpawner
    RoomRoot/
```

### DeterministicRandom

固定返回：

- `randf()`
- `randf_range()`
- `randi_range()`

用于 loot、reward、crit、evade、dungeon generation。

### Probe Services

必要时使用 test-only subclass 记录调用：

- `ProbeAnalyticsService extends AnalyticsService`
- `ProbeSaveable extends Saveable`
- `ProbeScreen extends Control`

这些只存在于 `test/integration/`，不进入 addon。

## Pipeline 覆盖矩阵

| Pipeline | Integration 覆盖方式 |
|---|---|
| Runtime Bootstrap Pipeline | `GameBootstrap.boot()` 注册所有核心服务，加载 `ResourceDatabase`，可选进入初始 scene。 |
| Content Load & Validation Pipeline | `ResourceDatabase.resources` 和 `ResourceDatabase.resource_paths` 都进入 `ContentRegistry.load_database() -> validate_all()`；其中 `resource_paths` 使用临时 `.tres` 验证真实 `load(path)`。 |
| Service Lookup Pipeline | 从 `ServiceRegistry` 获取每个 bootstrap service，并调用至少一个 public API。 |
| Main Gameplay Pipeline | `GameCommand -> CommandRouter -> CommandReceiver -> StateMachine -> ActionRunner -> EffectExecutor -> Module -> EventRouter` 端到端。 |
| Command Dispatch Pipeline | 注册 receiver，dispatch targeted command，验证 command consumed/history/signals。 |
| Event Notification Pipeline | domain 系统触发 `EventRouter.emit_*`，验证 typed signal 和 `recent_events`。 |
| HFSM Transition Pipeline | command 触发 state transition，验证 previous/current path 和 enter/exit 顺序。 |
| Action Lifecycle Pipeline | state 启动 action，验证 started/completed/cancelled 和 active action 清理。 |
| Time Scaling & Pause Pipeline | `TimeService` pause/scale 影响 `ActionRunner._process()` 的 action progress。 |
| Condition Evaluation Pipeline | ability/reward/loot 使用 passing/failing `Condition` 过滤。 |
| Effect Execution Pipeline | `EffectExecutor.execute_many()` 执行成功和失败 effect，验证 stop-on-failure。 |
| Scene Spawn & Object Pool Pipeline | `SpawnSceneEffect` 使用 direct load 或 `ObjectPool` acquire 实例化 scene。 |
| Entity Spawn Pipeline | `EntitySpawner.spawn_entity()` 从 `EntityDefinition` 实例化 scene，初始化 identity/stats/starting abilities。 |
| Stats & Modifier Pipeline | effect/status/equipment 添加 modifier，验证 final stat、signal 和移除。 |
| Resource Spend & Restore Pipeline | ability cost 消耗 mana/stamina，restore clamp 到 `max_<resource>`。 |
| Attack & Hitbox Pipeline | `HitboxComponent` 命中 `HurtboxComponent`，产生 damage request 并驱动 health/event。 |
| Ability Cast Pipeline | command 触发 ability cast，检查 cooldown/cost/conditions/effects/signals。 |
| Status Effect Pipeline | apply status，验证 stack rule、tick effects、duration expiry、modifier cleanup。 |
| Damage Resolution Pipeline | `DealDamageEffect -> CombatResolver -> HealthComponent`，验证 stats、crit、defense、event。 |
| Healing Pipeline | `HealEffect -> HealthComponent.heal()`，验证 max HP clamp 和 signal。 |
| Death Pipeline | lethal damage 触发 `HealthComponent.die()`、`EventRouter.entity_died`、room/run 响应。 |
| Enemy AI Pipeline | `SimpleAIEnemyBrain` think tick dispatch command 到 router。 |
| Interaction Pipeline | `InteractionComponent` 选择 nearby `Interactable`，执行 interact effects。 |
| Inventory Add & Remove Pipeline | `InventoryController.add_item/remove_item` stack、capacity、events。 |
| Item Pickup Pipeline | `GrantItemEffect` 创建 `ItemInstance` 并进入 inventory。 |
| Equipment Pipeline | equip/unequip item modifier，验证 stats 回滚。 |
| Loot Roll Pipeline | `LootSystem.roll_table()` deterministic weighted roll，conditions filter，生成 item instances。 |
| Reward Selection Pipeline | `RewardSystem.generate_options/apply_selected()`，执行 effects，发 reward event。 |
| Room Lifecycle Pipeline | `RoomController.setup/enter_room/spawn_enemies/entity_died/check_clear/generate_reward`。 |
| Run Lifecycle Pipeline | `RunDirector.start_run/enter_next_room/on_room_cleared/select_reward/complete/fail`。 |
| Dungeon Generation Pipeline | fixed seed 生成 deterministic `RoomGraph`，room order 和 length 正确。 |
| Experience & Level Up Pipeline | `ExperienceComponent.add_xp()` 跨多级升级，save payload 正确。 |
| Meta Progression & Upgrade Pipeline | currency、unlock、effects、content unlock signals。 |
| Save Pipeline | `SaveManager.save_game(root)` 收集多个 `Saveable`，写出 versioned payload。 |
| Load & Migration Pipeline | legacy save data 经过 `SaveMigration` 后恢复到 saveables。 |
| Scene Routing Pipeline | `SceneRouter.change_scene()` success/fail signal 和 transition lock。 |
| UI Screen Pipeline | `UIManager.open_screen/close_screen()` 实例化 screen，modal pause/resume gameplay。 |
| Feedback Pipeline | `FeedbackSystem` 监听 damage/death event，调用 damage number/VFX/audio collaborators。 |
| Analytics Pipeline | gameplay event 调用 injected `AnalyticsService` mock/probe。 |
| Rewarded Ad Pipeline | `AdServiceMock.show_rewarded_ad()` async complete 后 grant reward/revive。 |
| IAP Pipeline | `IAPServiceMock.load_products/purchase/restore` signals 和 purchased state。 |
| Cloud Save Pipeline | `CloudSaveServiceMock.save_to_cloud/load_from_cloud` round-trip dictionary。 |
| Debug Overlay Pipeline | `DebugOverlay` 绑定 target entity，读取 state/health/recent events。 |

## 建议 Test Files

### `test_runtime_bootstrap_integration.gd`

覆盖：

- Runtime Bootstrap Pipeline
- Content Load & Validation Pipeline
- Service Lookup Pipeline
- Platform service registration baseline

核心 cases：

- `test_tc_int_boot_01_boot_registers_all_services`
- `test_tc_int_boot_02_boot_loads_memory_resource_database_and_validation_passes`
- `test_tc_int_boot_03_boot_loads_tres_resource_path_and_validation_passes`
- `test_tc_int_boot_04_boot_is_idempotent_when_services_already_registered`

### `test_gameplay_pipeline_integration.gd`

覆盖：

- Main Gameplay Pipeline
- Command Dispatch Pipeline
- Event Notification Pipeline
- HFSM Transition Pipeline
- Action Lifecycle Pipeline
- Time Scaling & Pause Pipeline
- Condition Evaluation Pipeline
- Effect Execution Pipeline
- Ability Cast Pipeline
- Resource Spend & Restore Pipeline
- Item Pickup Pipeline
- Inventory Add & Remove Pipeline

核心场景：

1. Player receiver 接收 `BuiltinCommands.CAST_ABILITY`。
2. Current state 处理 command 并启动 cast/action。
3. Ability 检查 resource cost 和 condition。
4. `GrantItemEffect` 执行，item 进入 inventory。
5. `InventoryController` 发 `inventory_changed`，`EventRouter` 记录 domain event。
6. Cooldown 开始，resource 被扣除。
7. pause/scale 后 action progress 符合 `TimeService`。

核心 cases：

- `test_tc_int_game_01_command_to_ability_to_inventory_event`
- `test_tc_int_game_02_failed_condition_blocks_effects_and_emits_failure`
- `test_tc_int_game_03_time_pause_blocks_action_progress`
- `test_tc_int_game_04_effect_chain_stop_on_failure_preserves_previous_results`

### `test_combat_status_feedback_integration.gd`

覆盖：

- Attack & Hitbox Pipeline
- Damage Resolution Pipeline
- Healing Pipeline
- Death Pipeline
- Status Effect Pipeline
- Stats & Modifier Pipeline
- Feedback Pipeline
- Debug Overlay Pipeline

核心场景：

1. Source entity 有 attack/crit stats。
2. Target entity 有 hurtbox、health、status controller。
3. Hitbox active 后命中 hurtbox。
4. `CombatResolver` 计算 damage。
5. `HealthComponent` 应用 damage，触发 `damage_applied`。
6. on-hit status 应用 modifier，tick 后执行 tick effect，过期后清理 modifier。
7. lethal damage 触发 death，room/run 或 feedback listener 响应。
8. `DebugOverlay` 可读取 target health、state path 和 recent event。

核心 cases：

- `test_tc_int_cmb_01_hitbox_damage_status_and_feedback_event`
- `test_tc_int_cmb_02_heal_clamps_to_max_hp_and_emits`
- `test_tc_int_cmb_03_lethal_damage_emits_death_and_updates_debug_overlay`
- `test_tc_int_cmb_04_status_duration_expiry_removes_stat_modifier`

### `test_content_spawn_room_run_integration.gd`

覆盖：

- Scene Spawn & Object Pool Pipeline
- Entity Spawn Pipeline
- Room Lifecycle Pipeline
- Run Lifecycle Pipeline
- Dungeon Generation Pipeline
- Reward Selection Pipeline
- Loot Roll Pipeline

核心场景：

1. 临时保存 enemy entity scene 和 room scene。
2. `EntitySpawner` 使用 `EntityDefinition.scene_path` 生成 enemy。
3. `RoomController.enter_room()` spawn enemies。
4. enemy death 触发 room clear。
5. room reward pool 生成 deterministic reward options。
6. `RunDirector.start_run(seed)` 生成 deterministic room graph。
7. reward selected 后 run 进入下一房间或 complete。

核心 cases：

- `test_tc_int_run_01_spawn_entity_initializes_identity_stats_and_abilities`
- `test_tc_int_run_02_room_enter_spawns_enemies_and_clear_generates_reward`
- `test_tc_int_run_03_run_seed_generates_deterministic_room_graph`
- `test_tc_int_run_04_select_reward_applies_effect_and_advances_run`
- `test_tc_int_run_05_spawn_scene_effect_uses_pool_or_loads_scene`
- `test_tc_int_run_06_loot_roll_then_inventory_pickup_roundtrip`

### `test_progression_save_platform_integration.gd`

覆盖：

- Experience & Level Up Pipeline
- Meta Progression & Upgrade Pipeline
- Save Pipeline
- Load & Migration Pipeline
- Analytics Pipeline
- Rewarded Ad Pipeline
- IAP Pipeline
- Cloud Save Pipeline

核心场景：

1. Experience component 连续升级。
2. Progression unlock 消耗 currency、执行 effects、解锁 content id。
3. SaveManager 保存 player inventory/progression/experience 到临时 path。
4. 旧版本 payload 经 migration 后 load。
5. Analytics probe 记录 gameplay facts。
6. Ad/IAP/Cloud mock async signal 完成后状态可验证。

核心 cases：

- `test_tc_int_prog_01_xp_level_up_progression_unlock_and_save`
- `test_tc_int_prog_02_load_applies_migration_before_restore`
- `test_tc_int_prog_03_analytics_probe_records_runtime_event`
- `test_tc_int_prog_04_rewarded_ad_completion_grants_revival_or_reward`
- `test_tc_int_prog_05_iap_purchase_restore_roundtrip`
- `test_tc_int_prog_06_cloud_save_roundtrip_dictionary`

### `test_ui_interaction_ai_scene_integration.gd`

覆盖：

- Enemy AI Pipeline
- Interaction Pipeline
- Scene Routing Pipeline
- UI Screen Pipeline

核心场景：

1. `SimpleAIEnemyBrain` 根据 target/distance dispatch attack/move command。
2. `InteractionComponent` 选择 interactable 并执行 effects。
3. `SceneRouter` 切换临时 scene，验证 success/fail signal。
4. `UIManager` 打开 modal screen，`TimeService` pause，关闭后恢复。

核心 cases：

- `test_tc_int_ui_01_enemy_brain_dispatches_command_to_receiver`
- `test_tc_int_ui_02_interaction_executes_interactable_effects`
- `test_tc_int_ui_03_scene_router_emits_success_and_failure_paths`
- `test_tc_int_ui_04_modal_ui_pauses_and_closes_to_resume_time`

## 执行顺序计划

1. 建立 `test/integration/fixtures/` 或在每个 test file 内部定义最小 helper。优先少文件、低抽象，只有 scene/resource builder 重复明显时再抽 helper。
2. 先实现 `test_runtime_bootstrap_integration.gd`，确认 bootstrap、content、service 基线可靠；其中 content case 同时覆盖内存 resource 和临时 `.tres` resource path。
3. 实现 `test_gameplay_pipeline_integration.gd`，作为最高优先级端到端主链路。
4. 实现 combat/status/death/feedback/debug integration，覆盖高风险 runtime 状态变化。
5. 实现 spawn/room/run/reward/loot integration，覆盖需要临时 scene path 的链路。
6. 实现 progression/save/platform async integration，注意所有 save path 使用测试临时路径。
7. 实现 UI/interaction/AI/scene integration，必要时使用 minimal scenes/screens。
8. 为每个新增 `.gd` 运行 Godot/GUT 生成 `.gd.uid`。
9. 运行 `res://test/integration`，再运行相关 unit suite，确保 integration 没有污染 `ServiceRegistry` 或 runtime globals。

## 风险与约束

- `ContentRegistry` 的真实 path 加载要使用临时 `.tres`，并在 teardown 清理，避免遗留测试内容。
- `EntitySpawner`、`SceneRouter`、`SpawnSceneEffect` 依赖真实 `PackedScene` path，需要测试内创建可加载 scene resource。
- platform mocks 使用 timer async signal，测试必须 `await` 足够长或等待 signal。
- `ServiceRegistry` 是 autoload，全局污染风险高，必须每个 test 清理。
- `CombatResolver.get_default()` 是 static singleton，若后续测试修改其内部状态，需要显式恢复。
- `GameBootstrap` 会把部分 Node service 加到 `ServiceRegistry` autoload 下，测试 teardown 需要避免残留 child 影响后续 bootstrap。
- `UIManager`、`FeedbackSystem` 可能需要具体 child/root path，测试应使用最小可运行 scene tree，而不是绕过公开 API。

## 完成标准

- `docs/pipeline.md` 中每个 pipeline 至少被一个 integration case 明确覆盖。
- 所有随机选择 deterministic。
- 所有临时 save/scene/resource 文件可清理或位于测试临时路径。
- 测试不依赖 `game/demo/` 具体内容。
- 测试不修改 `addons/mkit/` runtime 行为。
- 新增 test code 时同步生成 `.gd.uid`。
