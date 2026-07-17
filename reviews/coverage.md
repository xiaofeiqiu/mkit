# 测试覆盖评估

## 结论

当前测试套件覆盖面较强，可以作为 `mkit` 当前架构和 live demo 的主回归网使用，但还不能称为全面覆盖。

强项在于：unit test 对核心服务和主要模块行为有大量边界断言；integration test 覆盖了从 `ModuleBootstrap`、`ServiceRegistry`、内容注册、命令/状态机/Action/Effect、战斗、任务、商店、世界切换、房间 run、存档到 UI/AI/交互的跨系统链路；`make demo-test` 又用真实 `game/bootstrap.tscn` 跑当前 demo 的完整黄金路径。

主要缺口在于：部分公共类只有最小直接测试，边界矩阵还不深；integration 多数仍是少数代表性路径，不是失败路径/排列组合矩阵；demo test 是 headless 单一路线，不能证明视觉、手感、音频可听性、布局和长时间稳定性。

## 本次扫描基线

本次实际运行：

```text
make ut         PASS
make int        PASS
make demo-test  PASS
```

GUT 统计：

| 范围 | 文件数 | 用例数 | 断言数 | 结果 |
| --- | ---: | ---: | ---: | --- |
| `test/unit/kernel` | 11 | 114 | 252 | PASS |
| `test/unit/modules` | 18 | 263 | 866 | PASS |
| `test/integration` | 11 | 43 | 1139 | PASS |
| 合计 GUT | 40 | 420 | 2257 | PASS |

Demo smoke：

| 入口 | 结果 | 完成信号 |
| --- | --- | --- |
| `make demo-test` -> `game/bootstrap.tscn --demo-auto-run` | PASS | `[AUTO] demo RPG loop complete` |

注意：`make ut` 和 `make int` 都先跑了 `tools/check_layering.py`，本次为 `check_layering: OK`。

## Unit Test 覆盖情况

### 覆盖较充分的区域

Kernel unit test 覆盖了主要基础服务：

- `ActionService`：启动、完成、取消、并行动作、重复 signal 连接、时间缩放。
- `CommandService` / `CommandReceiver`：注册、路由、失败信号、history、consumed 状态。
- `ContentService`：按 id 和类型查询、类型不匹配、未注册 id。
- `EffectService` / `GameEffect`：单 effect、effect chain、失败中断、trace buffer、内置 heal/damage/log。
- `EventService` / `DomainEvent`：订阅、退订、recent events、typed module event payload。
- `SaveService`：`roots` / `entities` / `scopes` 当前结构、重复 id、组件 key 冲突、旧 `payload` 拒绝、加载顺序、tmp path 覆盖。
- `ServiceRegistry`：注册、替换、查询、unregister、clear、typed port。
- `StateMachine`：嵌套 transition、can enter/exit、command bubble、enter/exit 顺序。

Module unit test 覆盖了主要玩法域：

- Combat/Ability：伤害、暴击、闪避、on-hit status、技能注册、冷却、费用、条件、cast time、pause。
- Inventory/Equipment：堆叠、容量、原子添加、移除、装备 modifier、save/load。
- Progression：货币、花费、升级前置、max level、save/load。
- Quest/Dialogue/Shop：接受、推进、turn-in、奖励失败、对话节点/选项、买卖、库存和价格。
- Loot/Reward/Room/Run：掉落权重、死亡掉落、奖励候选、房间清理、run 状态、奖励选择、scoped restore。
- Saveable components：Health、Stats、ResourcePool、StatusEffect、Ability、Inventory、Equipment 的 roundtrip。
- Entity contract/spawner、AudioService、QuestLogUI、module event payload。

### 本轮已补齐的 Unit 缺口

以下公共类已补上直接 unit 覆盖，避免只依赖上层链路间接触达：

- `ConditionEvaluator`
- `ContentValidationResult`
- `GameBootstrap`
- `Mkit`
- `AddCurrencyEffect`
- `SpendCurrencyEffect`
- `ResourceSet`
- `Wallet`
- `InventoryModel`
- `InventorySlot`
- `DialogueRuntime`
- `LootRollResult`
- `RoomLoader`
- `RewardCoordinator`

同时，原先几个 `assert_true(true)` 的 no-crash 用例已改为具体不变量断言，例如状态不变、signal 未发、原注册项仍存在。

### Unit 层剩余缺口

直接覆盖偏薄或主要依赖 integration 的区域：

- `TimeService`、`SceneService`、`PoolService` 缺少完整 unit 级 failure/edge matrix。
- `TargetInRangeCondition`、`CooldownReadyCondition`、`ConditionEvaluator` 的组合失败原因、null context、source/target 缺失路径不够系统。
- `CastAction`、`TimedAttackAction`、`DashAction` 多数通过 ability/demo 链路验证，直接 action 生命周期和取消语义还可补强。
- `ApplyStatusEffect`、`ApplyStatModifierEffect`、`AddCurrencyEffect`、`SpendCurrencyEffect`、`GrantItemEffect` 等 effect 类主要通过服务/链路验证，单 effect 边界条件不够均匀。
- `DungeonGenerator`、`RewardCoordinator`、`RoomLoader` 仍只有最小直接契约，复杂错误路径和空池/缺 scene/奖励失败排列仍偏少。
- 新增覆盖证明了纯状态对象的核心不变量，但 `Wallet`、`ResourceSet`、`InventoryModel` 后续仍可继续补更多异常输入和序列化边界。

## Integration Test 覆盖情况

### 覆盖较充分的链路

当前 43 个 integration test 覆盖了 `docs/pipeline.md` 中的主要管线主题：

- P0 Runtime Bootstrap：`test_runtime_bootstrap_integration.gd`
- Command / HFSM / Action / Effect / Ability：`test_gameplay_pipeline_integration.gd`、`test_scene8_full_tour_integration.gd`
- Damage / status / feedback：`test_combat_status_feedback_integration.gd`
- Entity spawn / room / run / reward / loot / object pool：`test_content_spawn_room_run_integration.gd`
- Quest / save / dialogue / shop / world：对应 pipeline integration 文件和 `test_village_rpg_loop_integration.gd`
- UI / interaction / AI / scene routing：`test_ui_interaction_ai_scene_integration.gd`
- 当前 live demo 的 Scene8 回归：`test_scene8_full_tour_integration.gd`

集成测试质量整体高于简单 smoke：大量用例检查 signal、domain event payload、状态对象、资源注册、真实 `Area2D` overlap、临时 `PackedScene`、存档 roundtrip、真实 demo scene/controller。

### Integration 层主要缺口

集成覆盖仍不是穷尽式：

- Quest、world、dialogue、shop 各自有代表性主路径，但失败恢复、重复操作、防重入、无效内容、并发/顺序边界在 integration 层不成矩阵。
- Scene/world/save 组合只覆盖关键 roundtrip，没有覆盖多 save slot、损坏文件、跨 zone 多次读档、部分 scope 缺失、实体删除后恢复等复杂恢复路径。
- UI 层验证的是服务注册、modal pause、scene routing、AI command、interaction effect，缺少真实屏幕布局、列表刷新、焦点切换、键鼠/手柄输入矩阵。
- `test_scene8_full_tour_integration.gd` 对 live demo 很有价值，但它是 demo 代码强绑定回归，不等于 addon API 的通用契约测试。
- 部分 integration teardown 仍产生日志噪音：`test_gameplay_pipeline_integration.gd` 有 5 个 orphan `State` 节点提示；多处 teardown 后出现 `Missing service: save` / `Missing service: pool` warning。当前不影响 PASS，但会降低日志作为异常信号的可信度。

## Demo Game Test 覆盖情况

`make demo-test` 是当前 live demo 的强 smoke gate。它启动真实入口：

```text
game/bootstrap.tscn -> game/village_rpg_demo.tscn
```

`--demo-auto-run` 覆盖的实际行为包括：

- `ModuleBootstrap` 服务注册和 `village_rpg_content.tres` 内容加载。
- 世界切换：Village、Elder Room、Field、trial cave overlay。
- 交互聚焦、portal、对话、主任务和手动任务。
- dash、Firebolt、projectile、burn tick、命令驱动战斗、敌人 AI 反击。
- Trial cave run：3 个房间、reward selection、temporary upgrade、完成状态。
- 装备 Field Blade、攻击力变化、商店买/卖、药水使用。
- feedback toast/shake、hit VFX cleanup、debug overlay 文本、SpawnSceneEffect。
- demo save payload 校验和读档恢复。

完成条件集中在 `_demo_missing_requirements()`，失败会让进程退出非 0；本次日志包含 `[AUTO] demo RPG loop complete`。

Demo test 的边界：

- 只有一条 deterministic golden path，不能证明所有玩家操作顺序、失败路线或重复进出场景都稳定。
- Headless 运行无法证明视觉质量：UI 重叠、文本可读、动画观感、摄像机 framing、分辨率适配都未被自动验证。
- 音频只证明资源和播放路径被触发，不证明用户实际听感、音量平衡或 bus 配置体验。
- 没有性能预算、帧时间、内存增长、长时间 idle/loop 稳定性断言。
- 没有把 Godot warning/ObjectDB/resource leak 作为失败条件。

## 总体风险判断

| 风险 | 当前状态 | 判断 |
| --- | --- | --- |
| 核心服务行为回归 | unit 覆盖强，integration 有关键链路 | 低到中 |
| 跨系统管线断裂 | 43 个 integration + demo auto-run | 中低 |
| 公共 API 边界遗漏 | 已补最小直接测试，effect/condition/action 边界仍不均匀 | 中 |
| Live demo 黄金路径 | `make demo-test` 强覆盖 | 低 |
| Demo UX/视觉/音频质量 | headless 无法验证 | 中高 |
| 测试日志卫生 | PASS 但存在 orphan/warning 噪音 | 中 |

## 建议补强优先级

1. 先清理测试卫生问题：消除 integration orphan `State`、teardown 后 `Missing service: save/pool` warning，并考虑让非预期 warning/leak 在 CI 中可见或失败。
2. 为 condition/effect/action 补一组更均匀的边界表：null context、缺 source/target、缺服务、失败 reason、stop-on-failure、cancel/pause。
3. 为 save/world/scene 增加 integration 负向恢复：损坏存档、缺失 scope、跨 zone 多次读档、防重入、实体已删除后恢复。
4. 为 demo 增加至少一层非 headless UX 观察或截图检查：主 HUD、dialogue/shop/reward UI、不同 viewport、关键文本不重叠。
5. 长期看，可以增加覆盖账本：按 `docs/pipeline.md` 的 20 个 pipeline heading 和 `addons/mkit` 公共类列出“unit / integration / demo / docs”覆盖状态，避免新增系统只靠人工记忆。

## 最终评估

当前测试不是“全面”，但已经是一个相当扎实的回归套件。它能有效保护主 gameplay pipeline、核心模块、当前 demo 黄金路径和近期 Scene8 回归；它不能替代公共 API 全量契约测试、复杂失败恢复矩阵、UX 视觉验证和长期稳定性测试。
