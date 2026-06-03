# Mkit RPG Modules — Implementation Plan / Tracker

> 本文件是 **可执行落地清单 + 进度追踪器**,与设计文档 [`spec/rpg-modules.md`](rpg-modules.md) 配套使用。
> 设计文档讲"每个 class 怎么设计";本文件讲"按什么顺序落地、现在做到哪了"。
> 每完成一项就把 `[ ]` 改成 `[x]`;接口细节去设计文档对应小节查,不在此重复。

## 如何维护本文件

- `[ ]` = 未实现
- `[x]` = 已实现 **且** 相关测试通过
- 🔄 行内标记 = 正在做(同一时间只标一项)
- 每个 milestone 完成后更新顶部「进度总览」的计数与日期。
- 一个新增 `.gd` 必须在勾选前:① 实现 ② 跑出 `.gd.uid` ③ 配套 unit + integration test 通过(见「测试规则」)。
- 改完一个 milestone 跑一次相关 `make ut*`,把真实结果贴进该 milestone 的「验证」行。

## 测试规则(强制 / Testing Rules)

> 这些规则适用于本计划每一个代码项。**没有配套测试的代码项不允许打 `[x]`。**

1. **代码与测试同批交付**:每实现一个 class / 一条 public API,就在**同一个 milestone 内**补它的 unit test —— 不把测试推到最后。
2. **unit + integration 都要做,且随增量进行**:每加一个模块,就同时补该模块的 unit test 和**至少一条贯穿真实管线**的 integration test,在该模块自己的 milestone 内完成,**不要全部堆到 M9**。"加一个东西就把 unit 和 integration 都做了"。
3. **测试必须 comprehensive**:unit test 覆盖 正常路径 + 边界值 + 失败/拒绝路径 + 事件发射 + 存档 round-trip + Condition 门槛;不能只测 happy path。每个 public 方法的关键分支都要有断言。
4. **以 developer 视角写 integration test**:假设你就是接入 mkit 的游戏开发者——通过 `ServiceRegistry` 取 service、调用 public 方法、监听 `EventRouter` 信号,把"开发者真实会怎么用"**端到端**跑出来(例:接任务 → 打怪 → 目标推进 → 发奖 → 存读档),而不是孤立地调一个内部方法。integration test 要尤其详细、贴近真实玩法链路。
5. **integration 用真实运行环境**:真实 `GameBootstrap` / `ServiceRegistry` / `EventRouter` / `EffectExecutor` + 临时 `ResourceDatabase` / `.tres` + deterministic `RandomService`;teardown 先 `for c in ServiceRegistry.get_children(): c.queue_free()` 再 `ServiceRegistry.clear()`(见 `spec/int-test.md` 约束),避免重复服务污染。
6. **每条新 pipeline 至少一个 integration case**,并在 `spec/int-test.md` 的覆盖矩阵登记。

## 进度总览

| Milestone | 内容 | 进度 | 状态 |
|---|---|---|---|
| M0 | Kernel 地基(改既有文件) | 4 / 4 | ✅ 完成 |
| M1 | quest 模块(含 unit + integration) | 11 / 11 | ✅ 完成 |
| M2 | dialogue 模块(含 unit + integration) | 0 / 10 | ☐ 未开始 |
| M3 | shop 模块(含 unit + integration) | 7 / 7 | ✅ 完成 |
| M4 | world 模块(含 unit + integration) | 0 / 7 | ☐ 未开始 |
| M5 | bootstrap 接线 | 0 / 2 | ☐ 未开始 |
| M6 | Audio 增强(可选) | 0 / 3 | ☐ 未开始 |
| M7 | quest_log UI(可选) | 0 / 1 | ☐ 未开始 |
| M8 | demo 内容(game/) | 0 / 6 | ☐ 未开始 |
| M9 | 全循环 integration + 矩阵登记 | 0 / 2 | ☐ 未开始 |
| M10 | 文档 | 0 / 4 | ☐ 未开始 |

**依赖顺序**:`M0 → M1 → M2 → M3 → M4 → M5 →(M6/M7)→ M8 → M9 → M10`。
M1–M4 之间彼此不在编译期硬依赖(跨模块只通过 data 引用 `GameEffect`/事件),可并行,但建议按序以便联调。

---

## M0 — Kernel 地基(改既有文件,先行)

> 这些改动是后续所有模块能被注册/索引/发事件的前提。无新增 `.gd`,故无新 `.uid`。

- [x] **`kernel/registry/content_registry.gd`** — 在 `_extract_content_id()` 的属性名列表追加 `quest_id`、`dialogue_id`、`shop_id`、`zone_id`(否则新 Definition 无法注册/查询)。
- [x] **`kernel/events/event_router.gd`** — 追加 typed signal 与 `emit_*`:`quest_accepted` / `quest_objective_advanced` / `quest_completed` / `quest_turned_in` / `dialogue_started` / `dialogue_ended` / `npc_talked` / `zone_changed` / `item_purchased` / `item_sold`(接口见设计文档「既有文件需要的最小改动 §2」)。
- [x] **`modules/inventory/item_definition.gd`** — 新增 `@export var value: int = 0`(商店定价基础值)。
- [x] **验证** — `make ut-kernel` 全绿;确认 `item_definition.value` 默认值不破坏现有 loot/inventory 测试。结果:新增 `test_content_registry.gd`(6 case)+ 扩展 `test_event_router.gd`(tc_er_13~22);`ut-kernel` 101/101 全绿,`ut-modules` 152/152 全绿(loot/inventory 无回归)。

---

## M1 — quest 模块(`modules/quest/`)

> 最高价值,是把战斗/掉落/对话/奖励串起来的枢纽。设计见「模块一」。

- [x] `quest_definition.gd` — `QuestDefinition`(Resource)
- [x] `quest_objective_definition.gd` — `QuestObjectiveDefinition`(Resource)
- [x] `quest_state.gd` — `QuestState`(RefCounted)
- [x] `quest_log.gd` — `QuestLog`(RefCounted)
- [x] `quest_system.gd` — `QuestSystem`(Saveable,service `quest`)
- [x] `advance_objective_effect.gd` — `AdvanceObjectiveEffect`(GameEffect)
- [x] `complete_quest_effect.gd` — `CompleteQuestEffect`(GameEffect)
- [x] `accept_quest_effect.gd` — `AcceptQuestEffect`(GameEffect,供对话选项接任务)
- [x] `test/unit/modules/test_quest_system.gd` — cases:
  - `test_tc_quest_01_accept_requires_prerequisites_and_conditions`
  - `test_tc_quest_02_kill_event_advances_objective_to_complete`
  - `test_tc_quest_03_item_acquired_event_counts_with_payload_key`
  - `test_tc_quest_04_auto_complete_grants_reward_effects`
  - `test_tc_quest_05_manual_turn_in_grants_reward_and_repeatable_resets`
  - `test_tc_quest_06_save_load_roundtrips_quest_log`
  - `test_tc_quest_07_accept_quest_effect_accepts_via_service`
  - `test_tc_quest_08_advance_objective_effect_advances_progress`
  - `test_tc_quest_09_complete_quest_effect_turns_in`
  - `test_tc_quest_10_complete_quest_effect_handles_auto_complete_turn_in`
  - `test_tc_quest_11_turn_in_keeps_completed_when_reward_fails`
- [x] `test/integration/test_quest_pipeline_integration.gd` — **开发者视角端到端**:真实 `GameBootstrap` 注册 `quest` service + 临时 `QuestDefinition`/`Objective` 进 ContentRegistry → `accept_quest` → 用真实战斗管线(`DealDamageEffect`→`CombatResolver`→`HealthComponent`→`entity_died`)击杀敌人 → QuestSystem 目标推进至完成 → `auto_complete` 跑 `reward_effects`(`GrantItemEffect` 入背包 / `add_currency`)→ `SaveManager.save_game` 存档再 load round-trip。覆盖 **Quest Pipeline**。
- [x] **验证** — 为新 `.gd` 生成 `.gd.uid`;`make ut-modules` + 该 integration 全绿。结果:`make ut-kernel` 101/101 全绿,`make ut-modules` 163/163 全绿,`make int` 1/1 全绿。Makefile 已为 unit / integration target 显式传 `--log-file`,避免本机 `user://logs` 轮转崩溃。

---

## M2 — dialogue 模块(`modules/dialogue/`)

> NPC 对话树,选项挂 Condition/Effect(可接 M1 的 quest effects)。设计见「模块二」。

- [ ] `dialogue_definition.gd` — `DialogueDefinition`(Resource)
- [ ] `dialogue_node.gd` — `DialogueNode`(Resource)
- [ ] `dialogue_choice.gd` — `DialogueChoice`(Resource)
- [ ] `dialogue_runtime.gd` — `DialogueRuntime`(RefCounted)
- [ ] `dialogue_controller.gd` — `DialogueController`(Node,service `dialogue`)
- [ ] `dialogue_interactable.gd` — `DialogueInteractable`(extends Interactable,发 `npc_talked`)
- [ ] `modules/ui/dialogue_ui.gd` — `DialogueUI`(Control)
- [ ] `test/unit/modules/test_dialogue_controller.gd` — cases:
  - `test_tc_dlg_01_start_enters_start_node_and_runs_enter_effects`
  - `test_tc_dlg_02_choices_filtered_by_conditions`
  - `test_tc_dlg_03_choose_runs_effects_and_advances`
  - `test_tc_dlg_04_linear_advance_until_end_emits_ended`
  - `test_tc_dlg_05_second_start_rejected_while_active`
- [ ] `test/integration/test_dialogue_pipeline_integration.gd` — **开发者视角端到端**:`InteractionComponent` 选中场景里的 `DialogueInteractable` → `try_interact` → `DialogueController.start` → `node_entered` 跑 on_enter_effects → `choose` 一个挂 `AcceptQuestEffect` 的选项 → 经 service `quest` 出现 active 任务 → `dialogue_ended` + `npc_talked` 事件推进"与 X 对话"任务目标。跨 **interaction + dialogue + quest**。覆盖 **Dialogue Pipeline**。
- [ ] **验证** — 生成 `.uid`;`make ut-modules` + 该 integration 全绿。结果:_(待填)_

---

## M3 — shop 模块(`modules/shop/`)

> 复用 progression 货币 + inventory,只补交易层。设计见「模块三」。依赖 M0(item value)。

- [x] `shop_definition.gd` — `ShopDefinition`(Resource)
- [x] `shop_entry.gd` — `ShopEntry`(Resource)
- [x] `shop_controller.gd` — `ShopController`(Node,service `shop`)
- [x] `modules/ui/shop_ui.gd` — `ShopUI`(Control)
- [x] `test/unit/modules/test_shop_controller.gd` — cases:
  - `test_tc_shop_01_buy_spends_currency_and_grants_item`
  - `test_tc_shop_02_buy_fails_when_currency_insufficient`
  - `test_tc_shop_03_stock_decrements_and_blocks_when_zero`
  - `test_tc_shop_04_sell_removes_item_and_adds_currency`
  - `test_tc_shop_05_price_override_and_multipliers`
- [x] `test/integration/test_shop_pipeline_integration.gd` — **开发者视角端到端**:经 `ServiceRegistry` 取 `shop` / `progression` / 买家 `Controllers/InventoryController` → `open_shop` → 货币不足时 `buy` 失败(`transaction_failed`)→ `add_currency` 后 `buy` 成功(扣币 + 入包 + `item_purchased` 事件)→ `sell` 回收(移除物品 + 加币)→ `stock` 递减为 0 后再买被拦。覆盖 **Shop Pipeline**。
- [x] **验证** — 生成 `.uid`;`make ut-modules` + 该 integration 全绿。结果:`make ut-kernel` 101/101、`make ut-modules` 172/172(新增 `test_shop_controller.gd` 5 case + `test_progression_system.gd` 补 `spend_currency` 4 case `prog_18~21`)、`make int` 2/2(quest + shop)全绿。补充改动:① `progression_system.gd` 新增公开 `spend_currency(currency_id, amount) -> bool`(设计文档 ShopController 假设其存在,实际仅在 `ProgressionState` 上,补到 System 层以发 `currency_changed`);② 沿用 M1/quest 先例,把 `shop` service 接入 `game_bootstrap.gd`(供 Shop Pipeline integration 走真实 bootstrap)。设计取舍:`ShopEntry.price_override >= 0` 时为最终买价(不再乘 `buy_price_multiplier`),倍率只作用于 `ItemDefinition.value`。

---

## M4 — world 模块(`modules/world/`)

> 带出生点的 zone 跳转,解决"出房间回到原位置"。设计见「模块四」。

- [ ] `zone_definition.gd` — `ZoneDefinition`(Resource)
- [ ] `spawn_point.gd` — `SpawnPoint`(Marker2D,group `spawn_point`)
- [ ] `portal.gd` — `Portal`(extends Interactable)
- [ ] `world_router.gd` — `WorldRouter`(Node,service `world`,包裹 SceneRouter)
- [ ] `test/unit/modules/test_world_router.gd` — cases:
  - `test_tc_world_01_go_to_zone_changes_scene_and_sets_pending_spawn`
  - `test_tc_world_02_player_placed_at_matching_spawn_point`
  - `test_tc_world_03_zone_changed_event_and_bgm_triggered`
  - `test_tc_world_04_missing_zone_definition_fails_gracefully`
- [ ] `test/integration/test_world_pipeline_integration.gd` — **开发者视角端到端**:临时保存两个含 `SpawnPoint` 的 `.tscn` → `WorldRouter.go_to_zone(zone, spawn)` → 真实 `SceneRouter.change_scene` → 玩家(group `player`)被移到匹配 `spawn_id` 的 SpawnPoint → `zone_changed`/`zone_entered` 事件触发 → 推进一个"到达 X"任务目标 + 注入的 AudioManager probe 收到 `play_music(bgm_id)`。覆盖 **World Navigation Pipeline**。
- [ ] **验证** — 生成 `.uid`;`make ut-modules` + 该 integration 全绿。结果:_(待填)_

---

## M5 — bootstrap 接线

> 依赖 M1–M4。设计见「既有文件需要的最小改动 §3」。

- [ ] **`kernel/bootstrap/game_bootstrap.gd`** — 在 `_register_kernel_services()` 后新增注册 `quest` / `dialogue` / `shop` / `world` 四个 Node service(构造 → `add_child` → `register_service(id, svc)`,与 `progression` 同模式)。`quest` 已在 M1、`shop` 已在 M3 为各自 Pipeline integration 接入,本项剩余 `dialogue` / `world`。
- [ ] **验证** — `make ut` 全量全绿(确认未污染 ServiceRegistry)。结果:_(待填)_

---

## M6 — Audio 增强(可选,不阻塞主功能)

> 改既有 `modules/ui/audio_manager.gd`。设计见「Audio 增强」。

- [ ] `play_music(music_id, fade_seconds)` 真正实现淡入淡出。
- [ ] 新增 `set_bus_volume(bus, db)` 并接 `Saveable` 持久化音量。
- [ ] 由 `WorldRouter.zone_changed` 驱动按 zone 自动换 BGM(M4 已预留调用)。

---

## M7 — quest_log UI(可选)

- [ ] `modules/ui/quest_log_ui.gd` — `QuestLogUI`(Control),订阅 QuestSystem 信号显示任务列表与进度。

---

## M8 — demo 内容(`game/demo/`,具体内容不进 addon)

> 验证"完整 RPG 循环"能真的跑通。设计见「game/ 内容放置」。

- [ ] `bootstrap_phase8.tscn` — 注册新 service + 加载新 ResourceDatabase。
- [ ] `phase8_village_rpg.tscn` + `phase8_village_rpg.gd` — 入口/驱动脚本。
- [ ] 场景:`village.tscn` / `village_room.tscn` / `field.tscn`(NPC + Portal + SpawnPoint + 刷怪 + 回村)。
- [ ] Resources:`QuestDefinition`/`QuestObjectiveDefinition`、`DialogueDefinition`/`DialogueNode`/`DialogueChoice`、`ShopDefinition`/`ShopEntry`、`ZoneDefinition`,并给现有怪/物品填 `value` 与 BGM/SFX 映射。
- [ ] NPC 实体:EntityRoot(无战斗组件)+ `DialogueInteractable`,沿用既有实体节点布局。
- [ ] **手动跑通** — 进村→进房间→NPC 对话接任务→出房→野外打怪掉落升级→任务自动/turn-in 发奖→回村商店补给→BGM/SFX 正常。结果:_(待填)_

---

## M9 — 全循环 integration + 矩阵登记

> 各模块的 integration 已分别在 M1–M4 完成。此处只做**跨全部模块的"完整 RPG 循环"端到端**,并把四条新 pipeline 登记进 `spec/int-test.md`。

- [ ] `test/integration/test_village_rpg_loop_integration.gd` — **完整循环**单场景串起:进 zone → NPC 对话接任务 → 出门到野外 → 打怪掉落 → 目标推进 + 升级 → turn-in 发奖 → 回村商店补给 → 存读档,全部经真实 service / 事件 / EffectExecutor,断言每一跳的状态与信号。
- [ ] 更新 `spec/int-test.md` 的「Pipeline 覆盖矩阵」与「建议 Test Files」,补 Dialogue / Quest / Shop / World Navigation 四条 pipeline 及对应 integration 文件。

---

## M10 — 文档(实现完成后)

> 设计见「文档计划」。中文概念段保持中文,标识符保持英文。

- [ ] `docs/ref/<ClassName>.md` — 为全部新 class 各建一页(沿用现有格式):QuestDefinition、QuestObjectiveDefinition、QuestState、QuestLog、QuestSystem、AdvanceObjectiveEffect、CompleteQuestEffect、AcceptQuestEffect、DialogueDefinition、DialogueNode、DialogueChoice、DialogueRuntime、DialogueController、DialogueInteractable、DialogueUI、ShopDefinition、ShopEntry、ShopController、ShopUI、ZoneDefinition、SpawnPoint、Portal、WorldRouter、QuestLogUI。
- [ ] `docs/module_layer.md` — 新增 quest / dialogue / shop / world 四个 domain 段落与 class 链接。
- [ ] `docs/pipeline.md` — 加入 Dialogue / Quest / Shop / World Navigation 四条新 pipeline。
- [ ] `docs/readme.md` — 更新 Docs Index 与 Core Data Model 例子(增加 `QuestDefinition -> QuestState -> QuestSystem` 等配对)。

---

## 最终完成标准(全勾后核对)

- [ ] `make ut` 全量全绿。
- [ ] 四条新 pipeline 各有 integration case 覆盖。
- [ ] phase8 demo 能手动跑通完整循环。
- [ ] 每个新 class 有 `docs/ref` 页;layer/pipeline/readme 已同步。
- [ ] 所有新 `.gd` 已生成并提交 `.gd.uid`。
- [ ] 无 addon→`game/` 反向依赖;addon 内无具体游戏内容(村名/NPC/任务/定价/地图都在 `game/`)。

## 变更记录

- _(创建)_ 初版落地计划,对应设计文档 `spec/rpg-modules.md`。
- _(更新)_ 新增「测试规则(强制)」;把 integration test 从 M9 下放到 M1–M4 各模块(代码与 unit+integration 同批交付、随增量推进、以 developer 视角端到端);M9 改为全循环 integration + 矩阵登记。
- _(更新)_ M1 quest 模块完成;新增 Quest Pipeline integration,并为 M1 integration 将 `quest` service 接入 `GameBootstrap`。
- _(更新)_ M3 shop 模块完成;新增 Shop Pipeline integration,并为该 integration 将 `shop` service 接入 `GameBootstrap`(M5 剩余 `dialogue` / `world`);为商店交易补 `ProgressionSystem.spend_currency`。
