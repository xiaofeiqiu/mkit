# mkit 设计过度工程评估

## Progress Tracker

- [x] 以当前源码为准梳理启动、服务注册、模块边界和测试基线。
- [x] 审阅 command/state/action/effect/event pipeline、实体契约和内容模型。
- [x] 审阅 save/load、world/run、demo 入口和文档概念是否把高级能力当默认路径。
- [x] 区分“必要的可复用复杂度”和“可以收敛的 overengineering 风险”。
- [x] 写出优先级建议和不建议继续增加的抽象。
- [x] 收敛第 2 项 save/load：demo 玩家改走 `EntitySaveAgent`，位置作为实体组件保存，避免 game 侧第二套玩家聚合器。
- [x] 完成风险 1：把完整 gameplay pipeline 收敛为 minimal / standard / advanced 三条文档路径。
- [x] 完成风险 1：同步 `CommandService`、`GameAction`、`ActionService` API 注释，强调按需使用边界。
- [x] 完成 P0：把“不要继续加新大抽象”落到 roadmap、architecture 和 addon README 的当前能力边界。
- [x] 完成 P1：把轻路径写成文档默认入口，并同步 `death_loot` 服务与 `RuntimeContext` 术语漂移。
- [x] 完成 P1：拆出 `DemoAutoRunVerifier` 与 `DemoSavePayloadVerifier`，让主 demo controller 不再承载 auto-run 和 save payload 断言。
- [x] 完成 P2：新增 `make contract-check`，静态检查 service id、实体场景契约、save id/scope 重复。
- [x] 完成 P2：新增 `docs/event_payloads.md`，并让 docs sync 校验公开事件与 payload key。
- [x] 完成 P2：把短路径 / 高级路径导航纳入 docs sync 检查，防止文档默认路径再漂移。

## 结论

当前 mkit 不是整体性 overengineering。核心内核比文档里的术语听起来简单：`project.godot` 只有一个 autoload `ServiceRegistry`，`ServiceRegistry` 本身只是一个 id 到服务实例的字典，`GameBootstrap`/`ModuleBootstrap` 通过显式 service table 装配运行时。`python3 tools/check_layering.py` 本次结果为 `check_layering: OK`，`addons/mkit/` 也没有实际引用 `res://game` 内容。

真正的风险集中在 4 个局部：

1. 完整 gameplay pipeline 容易被文档和 demo 呈现成所有操作都必须走的默认路径。
2. save/load 的 `roots + entities + scopes` 同时支持场景树扫描、实体聚合和显式 scope provider，能力强但心智负担高。
3. `RunDirector`/world/run 把 roguelike run、room graph、reward、scope restore 都纳入一个默认模块服务，和普通 2D RPG starter path 相比偏重。
4. `game/village_rpg_demo.gd` 原本把 showcase、UI 编排、scene router、auto-run 和 save payload 断言放在一个脚本里；P1 已先把 auto-run 与 payload verifier 拆到 game 侧 helper，剩余风险是继续收敛 runtime controller 观感。

所以建议不是大拆架构，而是收敛默认路径、拆轻重入口、修正文档术语，并明确哪些高级机制只在需要时启用。

## 证据快照

| 项 | 当前证据 | 判断 |
| --- | --- | --- |
| Autoload | `project.godot:18-20` 只注册 `ServiceRegistry` | 克制 |
| 服务注册 | `GameBootstrap._build_services()` 注册 kernel 服务，`ModuleBootstrap._build_services()` 追加模块服务，见 `addons/mkit/kernel/bootstrap/game_bootstrap.gd:47-60`、`addons/mkit/modules/module_bootstrap.gd:10-20` | 明确，非插件图谱 |
| 服务定位 | `ServiceRegistry.get_port()` 是薄字典查找，见 `addons/mkit/kernel/services/service_registry.gd:13-41` | 不复杂 |
| 类型化门面 | `Mkit` 只是静态 accessor，见 `addons/mkit/modules/mkit.gd:11-107` | 有样板但可接受 |
| addon 规模 | `addons/mkit` 约 140 个 `.gd`、138 个 `class_name`，其中 combat 27、world 15、loot 11 | 功能面较宽 |
| 测试面 | 38 个 GUT test 脚本，覆盖 kernel、modules、integration | 复杂度有回归网 |
| 文档面 | 24 篇 cookbook，generated API 来自 `##` doc comment | 对 reusable addon 合理 |

## 不是过度设计的部分

### ServiceRegistry / Mkit 门面

`ServiceRegistry` 没有做 DI container、生命周期图、模块拓扑排序或自动扫描；它只保存服务并在缺失时 warning。`GameBootstrap` 的服务表也是显式字典，不是隐式反射装配。这个设计对 Godot 项目比较务实，因为服务需要跨场景存在，且 Node 服务要挂到 autoload 下管理生命周期。

保留理由：

- `GameBootstrap` 对 Node 服务统一 `add_child`，对 `RefCounted` 服务只注册引用，见 `addons/mkit/kernel/bootstrap/game_bootstrap.gd:63-79`。
- `Mkit.xxx()` 让调用点获得类型提示，减少散落字符串和 cast。
- `docs/roadmap.md:7-19` 已明确不承诺模块自动扫描、拓扑排序或第三方模块自动加载。这是正确边界。

可收敛点：

- 文档中继续使用 `RuntimeContext`、`runtime port` 会显得比当前代码复杂。当前源码没有 `MkitRuntimeContext`、`set_runtime_context`、`register_port` 这类实现；`docs/architecture.md:59` 的标题和 `docs/readme.md`、`docs/cookbook/index.md` 里的相关术语应改成“ServiceRegistry + Mkit service accessor”。
- `ModuleBootstrap` 实际注册了 `DeathLootService`，见 `addons/mkit/modules/module_bootstrap.gd:19`；部分文档仍写“7 个内置模块服务”且服务表没有列 `death_loot`。这会让模块面看起来不清晰。

### ContentDefinition / ResourceDatabase / ContentService

内容模型不算 overengineering。Godot 本身鼓励 `.tres`/`Resource` 资产化，`ContentDefinition.get_content_id()`、`ResourceDatabase.get_all_resources()`、`ContentService.register_resource()` 的职责很窄，见 `addons/mkit/kernel/registry/content_definition.gd:10-12`、`addons/mkit/kernel/registry/resource_database.gd:17-27`、`addons/mkit/kernel/registry/content_service.gd:16-38`。

保留理由：

- 稳定 id、重复 id fail-fast、按类型索引，都是 data-driven RPG addon 的基础能力。
- 定义资源多是功能面宽导致的，不是抽象层无收益。

### Definition -> Runtime -> Component -> Service 四分模式

这个模式对 RPG/roguelike 模块是合理的。`AbilityDefinition`、`AbilityInstance`、`AbilityController`、`ActionService` 这类分工让静态配置、每实体状态、节点生命周期、全局流程各自有清楚归属。`docs/architecture.md:112-133` 的描述基本符合源码。

风险不是模式本身，而是任何小功能都照搬全套四层。建议把它作为复杂系统的默认结构，而不是每个简单 effect、UI 小状态或 demo glue 的强制模板。

## 有 overengineering 风险的部分

### 1. 完整 gameplay pipeline 作为默认心智模型偏重

当前 pipeline 是：

```text
Input / AI / Script
-> GameCommand / CommandReceiver
-> optional CommandService
-> StateMachine / State
-> GameAction / ActionService
-> GameEffect / EffectService
-> Domain service/component
-> EventService
-> UI/audio/VFX
```

每层源码都很薄：

- `CommandReceiver.receive_command()` 只是记录、交给状态机、fallback，并 mark consumed，见 `addons/mkit/kernel/commands/command_receiver.gd:61-76`。
- `ActionService.start_action()`/`_process()` 负责 action 生命周期和时间缩放，见 `addons/mkit/kernel/actions/action_service.gd:29-58`。
- `GameAction.start()`/`complete()` 统一触发 effects，见 `addons/mkit/kernel/actions/game_action.gd:34-69`。
- `EffectService.execute_many()` 是简单顺序执行，见 `addons/mkit/kernel/effects/effect_service.gd:19-39`。

这说明 pipeline 的代码复杂度不高，但“必须理解所有层才能做一次攻击”的认知成本高。好消息是源码已经提供短路径：

- `CommandService` 是可选的；调用方持有实体时可以直接找 `CommandReceiver`。
- 即时技能不进 `ActionService._process()`，`AbilityController` 会创建 `GameAction` 后同帧 `start()` + `complete()`，见 `addons/mkit/modules/combat/abilities/ability_controller.gd:112-129`。
- 简单同步效果可以直接调用 service/component，只有需要数据驱动、条件、trace、订阅时才上 `GameEffect`。

建议：

- 文档明确三条路径：minimal path、standard path、advanced path。
- `CommandService` 文档继续强调“只知道 target_id 时用”，不要把它写成输入必经层。
- `GameAction` 文档强调“需要跨帧、可取消、统一 effect 时用”；普通同步查询不要包装成 action。

完成状态：

- 已在 `docs/concepts.md`、`docs/readme.md`、`docs/pipeline.md` 增加 minimal / standard / advanced 路径选择说明；`docs/cookbook/index.md` 只保留判断规则，23 个具体 recipe 均补充了 `## 本篇路径`，按本篇语境逐步写出 minimal / standard / advanced 路径（存在时）的跟做步骤、关键代码片段和验证结果。
- 已在 `addons/mkit/kernel/commands/command_service.gd` 中把 `CommandService` 定位为只知道 `target_id` 时使用的可选路由。
- 已在 `addons/mkit/kernel/actions/game_action.gd` 和 `addons/mkit/kernel/actions/action_service.gd` 中把 `GameAction` / `ActionService` 定位为跨帧、可取消或统一 effect 链的高级路径。

### 2. SaveService 同时承载三种存档模型，能力强但心智负担高

`SaveService.save_game()` 同时写：

- `roots`：场景树中的 `Saveable`；
- `entities`：`EntitySaveAgent` 聚合的实体组件；
- `scopes`：`Saveable.get_save_scopes()` 和显式注册的 scope provider。

证据见 `addons/mkit/kernel/save/save_service.gd:36-87`、`addons/mkit/kernel/save/save_service.gd:125-180`、`addons/mkit/kernel/save/entity_save_agent.gd:32-87`。

这套设计不是无意义的复杂：world zone、run/room/reward 这类跨场景状态确实需要 scope provider；实体组件确实需要 `EntitySaveAgent` 防止每个组件都变成全局 root。测试也覆盖了当前 envelope、重复 id、旧字段拒绝和加载顺序，见 `test/unit/kernel/test_save_service.gd:84-127`、`test/unit/kernel/test_save_service.gd:130-174`、`test/unit/kernel/test_save_service.gd:177-245`。

主要风险原本在于三种 envelope 入口容易被理解成三套并列玩法。更好的设计不是删掉其中任何一层，而是把它们解释为三种所有权：

| 保存对象 | 推荐入口 | 判断标准 |
| --- | --- | --- |
| 全局系统状态 | `Saveable` -> `roots` | 不属于某个实体，随服务或常驻节点存在，例如 quest/progression/audio |
| 实体局部状态 | `EntitySaveAgent` -> `entities` | 属于一个可生成、可跨场景存在或需要稳定 entity id 的实体 |
| 跨场景系统切片 | save scope provider -> `scopes` | 需要在场景树节点缺席时仍可恢复，例如 world zone、run/room/reward |

已收敛：

- `game/entities/player.tscn` 现在直接挂 `EntitySaveAgent`，`entity_id` 与现有 `EntityIdentity` / `CommandReceiver` 的 `player_001` 对齐。
- 原 `game/player_saveable.gd` 已删除；玩家位置改为实体内的 `PositionSaveComponent`，作为普通 `SaveableComponent` 进入 `entities.player_001.components.Position`。
- `EquipmentController.from_save_data()` 在恢复装备前清理即将恢复装备的 modifier source，避免 `StatsComponent` 先恢复 persistent modifier、装备再恢复时重复叠加。
- Scene8 存档集成测试已断言 `roots.demo_player` 不再出现，并验证玩家组件从 `entities.player_001.components` 恢复。
- `_collect_saveables(root)` 和 `_collect_entity_agents(root)` 仍会扫描场景树，显式注册 scopes 又提供另一条入口。能力多，但现在规则由所有权区分。
- envelope 内大量数据仍是 `Dictionary`，schema 靠约定和测试，不靠类型承载。

建议：

- 继续保持一条推荐规则：全局 singleton 用 `Saveable` root；实体组件用 `EntitySaveAgent`；跨场景但没有场景 root 的系统用 save scope provider。
- game 侧如有特殊实体状态，优先写成小型 `SaveableComponent` 或 duck participant，挂回实体树下，而不是另写一个外部 `Saveable` 聚合整个实体。
- 暂时不要再引入更通用的 save manifest、反射 schema 或迁移框架。当前已经够用，下一步应是持续补足文档和测试边界。

### 3. World / RunDirector 对普通 RPG 路径偏重

`WorldService` 本身不重：zone id、scene routing、spawn placement、BGM、zone save scope，见 `addons/mkit/modules/world/world_service.gd:37-62`、`addons/mkit/modules/world/world_service.gd:84-190`。

重的是 `RunDirector`。它同时处理：

- 多 save scope：`world.run`、`world.room`、`world.reward`；
- room graph 序列化和恢复；
- run state、room runtime、reward history；
- room scene loading、room cleared、reward selection；
- death event 订阅和 run failure。

证据见 `addons/mkit/modules/world/dungeon/run_director.gd:57-83`、`addons/mkit/modules/world/dungeon/run_director.gd:86-190`、`addons/mkit/modules/world/dungeon/run_director.gd:207-430`。

这对 roguelike sample 是有价值的，但对“2D RPG kernel + modules”的默认学习路径偏重。`game_template/` 已经提供更轻入口，`game_template/starter_scene.gd` 187 行能展示 command、event、quest 的最小循环；`game_template/README.md:1-3` 也明确它和完整 demo 分离。

建议：

- 把 `RunDirector` 文档定位为 advanced roguelike run module，不要放在第一层 onboarding。
- 普通 RPG cookbook 先走 `WorldService.go_to_zone()`、quest/dialogue/shop/combat，不要求理解 run graph。
- 不要把 `RunDirector` 再泛化成“所有流程导演”。如果未来要支持多种 run 类型，先拆文档和示例，再考虑代码拆分。

### 4. DomainEvent payload 仍是弱类型边界

`DomainEvent` 只有 `event_type/source_id/target_id/payload`，payload 是 `Dictionary`，见 `addons/mkit/kernel/events/domain_event.gd:9-20`。各模块有事件工厂，例如 `CombatEvents.damage_applied()`、`QuestEvents.quest_accepted()`、`WorldEvents.zone_changed()`，这能减少散落字符串；但消费者仍要知道 payload key。

风险点：

- `QuestService` 订阅 `EventService.ANY_EVENT`，再按 `objective.event_type` 和 payload key 匹配，见 `addons/mkit/modules/quest/quest_service.gd:42-48`、`addons/mkit/modules/quest/quest_service.gd:93-116`、`addons/mkit/modules/quest/quest_service.gd:235-245`。这很灵活，也最容易产生隐式契约。
- `CombatEvents` 会把 `DamageResult` 对象和 debug dict 都塞进 payload，见 `addons/mkit/modules/combat/combat_events.gd:13-22`。调试方便，但边界不是强类型。

建议：

- 保留 `DomainEvent`，不要上完整 event DSL 或 catalog compiler。
- 对高频公共事件补 typed accessor 或小型 payload carrier，例如 damage、entity_died、inventory_changed、zone_changed。低频事件继续用 Dictionary。
- docs/ref 中列出每个公共事件的 payload key，而不是只写事件名。

### 5. 实体契约是必要约束，但路径字符串仍多

`EntityRoot`/`EntityContract` 把 `Components/`、`Controllers/`、`Presentation/AnimationPlayer` 这些约定集中起来，见 `addons/mkit/kernel/entity/entity_root.gd:45-70`、`addons/mkit/kernel/entity/entity_contract.gd:21-64`。这比各模块自己到处 `owner.get_node_or_null("Components/...")` 好。

风险点：

- 模块侧仍有很多具体字符串，如 `"StatsComponent"`、`"HealthComponent"`、`"AbilityController"`，调用点需要知道场景结构。
- game 侧状态脚本仍大量直接取 `Components/...`，例如 `game/entities/states/player_attack_state.gd:14-36`、`game/entities/states/player_cast_ability_state.gd:11-22`、`game/entities/states/player_move_state.gd:41-45`。game-owned 代码可以这样写，但作为示例会削弱 `EntityContract` 的推荐一致性。

建议：

- 保留实体契约，不要改成更抽象的 component registry 或 ECS。
- 增加或强化实体 scene contract 检查，优先用 lint/test 抓缺失节点，而不是再加一层运行时动态查找框架。
- 示例状态脚本可逐步改用 `EntityContract`，至少新文档不要再展示直接路径作为推荐方式。

### 6. 完整 demo 是最大“过重观感”来源

`game/village_rpg_demo.gd` 原本同时承担：

- demo content 常量和内嵌 `EmbeddedSceneRouter`，见 `game/village_rpg_demo.gd:4-67`；
- service resolution、UI binding、audio、starter currency、zone entry、auto-run 启动；
- command/ability/combat/trial/shop/dialogue/save/hud orchestration；
- demo save payload 的内部结构断言。

这不是 addon 过度设计，但它是 sample 设计债。P1 之后 `game/village_rpg_demo.gd` 仍是完整 showcase controller，但 `--demo-auto-run` 的路线、DebugOverlay/VFX 检查和 save payload JSON 断言已经拆到 `game/demo_auto_run_verifier.gd` 与 `game/demo_save_payload_verifier.gd`，新使用者不再需要把这些 smoke harness 误读为普通玩法模板。

建议：

- 已拆出 `DemoAutoRunVerifier`、`DemoSavePayloadVerifier`。后续若继续收敛，可再拆 `DemoRuntimeController`，但不要改 addon API 来解决 sample 观感问题。
- 继续把 `game_template/` 放在 onboarding 第一屏。它是证明“mkit 可以轻量使用”的关键资产。
- demo 内部 payload 断言更适合迁移到 GUT 或专门 smoke helper，避免主场景脚本知道太多 save envelope 内部细节。

## 优先级建议

### P0：不要继续加新大抽象

短期不要加：

- runtime module graph / auto module discovery；
- `MkitRuntimeContext` 或第二套 service port 容器；
- 通用 event DSL；
- 通用 save schema/migration framework；
- ECS/component registry 替代当前 EntityContract。

这些都可能把当前局部复杂度变成整体过度工程。当前更需要收敛用法和示例，而不是再抽象。

完成状态：

- 已在 `docs/roadmap.md` 的“当前实现边界 / 暂不承诺的能力”中明确这些 non-goals。
- 已在 `docs/architecture.md` 中把当前服务边界收敛为 `ServiceRegistry / Mkit`，并避免把 module graph、event DSL、通用存档迁移框架或 ECS/component registry 写成当前能力。
- 已在 `addons/mkit/README.md` 中为 addon 使用者补充相同边界，防止入口文档继续暗示更大的 runtime abstraction。

### P1：把“轻路径”写成官方默认

建议在 docs/cookbook 和 getting started 里明确：

| 需求 | 推荐最小路径 |
| --- | --- |
| 有节点引用，发送命令给本实体 | `EntityContract.get_command_receiver(...).receive_command(...)` |
| 只知道目标 id | `Mkit.commands().dispatch(...)` |
| 即时数值变化 | 直接调用 component/service，或用单个 `GameEffect` |
| 有前摇、持续、取消、统一 effects | `GameAction` + `ActionService` |
| 普通 zone 切换 | `WorldService.go_to_zone()` |
| roguelike 房间 run | `RunDirector` |
| 单个全局系统存档 | `Saveable` |
| 实体组件聚合存档 | `EntitySaveAgent` |
| 跨场景系统 scope | `register_saveable_scope()` |

完成状态：

- `docs/readme.md`、`docs/cookbook/index.md`、`docs/getting_started.md` 已把短路径 / minimal path 放在完整 pipeline 之前。
- `docs/getting_started.md` 和 `game/README.md` 明确 `game_template/` 是小起点，village RPG demo 是完整 showcase。

### P1：修正文档概念漂移

需要同步清理：

- `RuntimeContext` / `runtime context` / `runtime port` 术语残留；
- `ModuleBootstrap` 服务数量与 `DeathLootService` 的文档遗漏；
- “完整 pipeline” 与 “可选短路径” 的关系；
- `village_rpg_demo.gd` 与 `game_template/` 的使用定位。

完成状态：

- `docs/architecture.md` 已改为 `ServiceRegistry / Mkit` 服务访问模式，内置模块服务列表包含 `death_loot`。
- `docs/getting_started.md` 的 `ModuleBootstrap` 输出说明已包含 `death_loot`。
- `docs/error_reporting.md` 已把残留 runtime port 表述改为 service lookup 缺失。

### P1：拆 demo 的测试胶水

优先拆 `game/village_rpg_demo.gd` 中的 auto-run 和 save payload verifier。这样不改变 addon API，却能显著降低项目外观复杂度。

完成状态：

- `game/demo_auto_run_verifier.gd` 承载 `--demo-auto-run` 的自动路线、DebugOverlay 检查、Trial 自动推进和 VFX cleanup 检查。
- `game/demo_save_payload_verifier.gd` 承载 demo save JSON payload 断言、scramble/load round-trip 和恢复结果检查。
- `game/village_rpg_demo.gd` 保留玩家交互、UI 编排、scene routing 和 demo runtime 状态，auto-run 入口只委托给 verifier。

### P2：强化契约检查，而不是加运行时抽象

当前最大的脆弱点是约定字符串：服务 id、事件 payload key、实体节点名、save id/scope。建议用检查器和测试补强：

- entity scene contract checker；
- public event payload docs/check；
- save id/scope duplicate checker；
- docs 中的“短路径/高级路径”导航检查。

这些比引入更通用的动态注册系统更划算。

完成状态：

- 已新增 `tools/check_runtime_contracts.py` 和 `make contract-check`；它会检查 `SERVICE_ID` 重复、`EntityRoot` 场景是否保留 `EntityIdentity` / `StateMachine` / `CommandReceiver` / `Components` / `Controllers` / `Presentation`，以及 addon/game 中的 save id/scope 重复。
- 已把 `game/entities/player.tscn` 的表现节点归入 `Presentation/`，让当前 demo 玩家也符合实体默认布局。
- 已新增 `docs/event_payloads.md`，列出内置模块固定 `DomainEvent` 的 `event_type`、source/target 语义和 payload keys。
- 已扩展 `tools/check_docs_sync.py`：从模块 `*_events.gd` 读取公开事件常量，并要求事件 payload 文档覆盖每个事件；同时要求 `readme.md`、`concepts.md`、`pipeline.md`、`cookbook/index.md` 保留 minimal / standard / advanced 路径导航。
- 已更新 `AGENTS.md` 和 `Makefile`，把 contract check 纳入本地 `make check`。

## 最终判断

mkit 的设计复杂度主要来自目标范围：它不是单个 demo，而是 reusable Godot RPG/roguelike runtime。以这个目标看，`ServiceRegistry`、内容注册、实体契约、Action/Effect、domain services 和 generated docs 都有明确收益。

但当前呈现方式有 overengineering 风险：完整 demo 太大、save/run 太早暴露、文档还残留未来架构词、事件和存档仍有弱类型 Dictionary 边界。最务实的下一步是“收窄默认心智模型”，不是重写框架。
