# Scene8 全类覆盖测试计划 (scene8test.md)

## 进度跟踪 (Progress Tracker)

> 完成一个 slice 就把对应项从 `[ ]` 改成 `[x]`。每项须满足"实例化 + 触发 + 集成测试断言 + `make ut` 绿"。

- [x] **S0** — command→HFSM→action 链接入自动化并断言(命令 / 状态机 / 动作 / hitbox-hurtbox,11 类)
- [x] **S1** — 技能管线:消耗 / 冷却 / 条件 / 命中施加状态(abilities + conditions + ResourcePool,10 类)
- [x] **S2** — 状态效果 + 属性修饰(status / stat-modifier + LogEffect,8 类)
- [x] **S3** — 装备(`EquipmentController` + 可装备 item + StatModifier,1 类)
- [ ] **S4** — 数据驱动生成实体(`EntityDefinition` / `EntitySpawner`,2 类)
- [ ] **S5** — 敌人 AI(`Brain` / `SimpleAIEnemyBrain` / `Blackboard`,3 类)
- [ ] **S6** — 试炼洞窟:Roguelike 单局(Room / Run / Dungeon / Reward,13 类,方案 A)
- [ ] **S7** — 存档协调(`SaveManager` / `Saveable` / `SaveableComponent` / `SaveMigration`,4 类)
- [ ] **S8** — 平台服务钩子(Analytics / Ads / IAP / CloudSave,8 类)
- [ ] **S9** — 表现层 + 运行时工具(DamageNumber / VFX / SpawnScene / Feedback / UIManager / Debug / Pool / Time,8 类)
- [ ] **S10** — 收尾:就近交互 / 手动任务 effect / 冲刺(`InteractionComponent` / `AdvanceObjectiveEffect` / `CompleteQuestEffect` / `DashAction`,4 类)
- [ ] **S11** — 退役 phase0–7,demo 收敛到唯一入口(`bootstrap_phase8` / `project.godot` 主场景)

覆盖账:当前 ✅ 66 类;S0–S10 接入剩余 66 类(其中 `RandomService` / `ActionContext` / `StatsComponent` 3 个随宿主 slice 顺带断言);全部完成后 = **132 / 132**,零豁免。详见 §2 矩阵与附录映射表。

---

> 把 `game/demo/phase8` 这套村庄 RPG loop demo 扩展成 mkit 的"全类覆盖活体场景":
> 让 `addons/mkit/` 下每一个 `class_name` 都至少被 phase8 **场景 + 内容 + 配套集成测试**
> 真实地实例化并触发一次有意义的行为(不是仅把节点挂在 scene 树里),并由 GUT 集成测试断言、
> 由 `--phase8-auto-run` headless 跑通。
>
> **最终目标:phase8 成为唯一保留的 demo 场景,删除 phase0–phase7。** 因此 phase8 必须先是
> phase0–7 全部演示能力的**超集**(每个旧 phase 都能对应到本计划的某个 slice),覆盖确认无丢失后,
> 才在收尾里程碑 **S11** 删除旧场景、并把 demo 入口收敛到 phase8。

相关文件:

- 场景:`game/demo/phase8_village_rpg.tscn` + `.gd`,子场景 `game/demo/phase8/scenes/{village,village_room,field}.tscn`
- 实体:`game/demo/phase8/entities/{npc_elder,field_beast}.tscn`、`game/demo/entities/player/player.tscn`
- 内容:`game/demo/phase8/resources/phase8_rpg_content.tres`(单一 `ResourceDatabase`)
- 引导:`game/demo/bootstrap_phase8.tscn`(`GameBootstrap` + 上面这份内容库)
- 现有集成测试:`test/integration/test_village_rpg_loop_integration.gd`
- 助手:`test/integration/int_test_helpers.gd`(已有 `make_*` / `add_*` 工厂)

---

## 1. 结论速览

addon 共 **132** 个 `class_name`(kernel 51 + modules 81)。按 phase8 当前状态分三档:

| 档位 | 含义 | 数量 |
|------|------|------|
| ✅ 已覆盖 | phase8 当前(交互或 auto-run)会真实触发,且已被集成/单元测试断言 | **57** |
| 🟡 已挂载/可达但未断言 | 节点已在 player/beast/elder scene 里,或 player input 路径可触发,但 auto-run + 集成测试没驱动/没断言(部分还缺内容) | **21** |
| ❌ 完全缺失 | addon 有该类,但 phase8(场景+内容+测试)完全没用到 | **54** |

> 关键发现:`player.tscn` 已经自带一整条 **command → HFSM → action** 输入链
> (`player_input_reader.gd`:WASD 走 `MOVE`、Space/J 走 `ATTACK`、Q 走 `CAST_ABILITY`)。
> 这些类在**交互运行**时其实可达,只是 `phase8_village_rpg.gd` 的 auto-run / 集成测试从不驱动它们,
> 且 `Q` 引用的 `ability.fireball_basic` 在 phase8 内容里并不存在(cast 必失败)。
> 所以"🟡"很多并非要新写系统,而是要 **让自动化路径真正驱动并断言这些已有链路** + 补内容。

---

## 2. 覆盖矩阵(按层 / 模块)

### Kernel(51)

| 文件夹 | ✅ 已覆盖 | 🟡 可达未断言 | ❌ 缺失 |
|--------|-----------|----------------|---------|
| services | `SceneRouter` | `RandomService`(loot/combat 内部用) | `TimeService` `ObjectPool` `AnalyticsService(+Mock)` `AdService(+Mock)` `IAPService(+Mock)` `CloudSaveService(+Mock)` |
| debug | — | — | `DebugOverlay` |
| effects | `EffectExecutor` `GameEffect` `EffectResult` `DealDamageEffect` `HealEffect` `GrantItemEffect` `ApplyStatusEffect` `ApplyStatModifierEffect` `LogEffect` | — | `SpawnSceneEffect` |
| save | — | `SaveManager` `Saveable` `SaveableComponent` | `SaveMigration` |
| bootstrap | `GameBootstrap` | — | — |
| context | `GameplayContext` `ActionContext` | — | `Blackboard` |
| commands | `CommandRouter` `CommandReceiver` `GameCommand` `BuiltinCommands` | — | — |
| conditions | `Condition` `ConditionEvaluator` `CooldownReadyCondition` `TargetInRangeCondition` | — | — |
| events | `EventRouter` `DomainEvent` | — | — |
| registry | `ResourceDatabase` `ContentRegistry` `ContentValidationResult` | — | — |
| state_machine | `StateMachine` `State` | — | — |
| actions | `ActionRunner` `GameAction` `TimedAttackAction` `CastAction` | — | `DashAction` |

### Modules(81)

| 模块 | ✅ 已覆盖 | 🟡 可达未断言 | ❌ 缺失 |
|------|-----------|----------------|---------|
| entity | `EntityIdentity` `EntityRoot` | — | `EntityDefinition` `EntitySpawner` |
| stats | `StatsComponent` `StatDefinition` `StatModifier` `StatModifierDefinition` | — | — |
| health | `HealthComponent` `ResourcePoolComponent` | — | — |
| combat | `CombatResolver` `DamageRequest` `DamageResult` `HitboxComponent` `HurtboxComponent` | — | — |
| abilities | `AbilityController` `AbilityDefinition` `AbilityInstance` | — | — |
| status_effects | `StatusEffectController` `StatusEffectInstance` `StatusEffectDefinition` | — | — |
| inventory | `InventoryController` `InventoryModel` `InventorySlot` `ItemDefinition` `ItemInstance` `EquipmentController` | — | — |
| loot | `LootSystem` `LootTableDefinition` `LootEntry` `LootRollResult` | — | `RewardSystem` `RewardDefinition` `RewardOption` |
| room | — | — | `RoomDefinition` `RoomRuntime` `RoomController` `RoomGraph` `RoomNode` `RunDirector` `RunState` `DungeonGenerator` |
| world | `WorldRouter` `ZoneDefinition` `Portal` `SpawnPoint` | — | — |
| progression | `ProgressionSystem` `ProgressionState` `ExperienceComponent` `ExperienceCurve` | — | `UpgradeDefinition` |
| shop | `ShopController` `ShopDefinition` `ShopEntry` | — | — |
| quest | `QuestSystem` `QuestDefinition` `QuestObjectiveDefinition` `QuestState` `QuestLog` `AcceptQuestEffect` | — | `AdvanceObjectiveEffect` `CompleteQuestEffect` |
| dialogue | `DialogueController` `DialogueDefinition` `DialogueNode` `DialogueChoice` `DialogueInteractable` `DialogueRuntime` | — | — |
| interaction | `Interactable` | — | `InteractionComponent` |
| ai | — | — | `Brain` `SimpleAIEnemyBrain` |
| ui | `DialogueUI` `QuestLogUI` `ShopUI` `AudioManager` | — | `FeedbackSystem` `UIManager` `DamageNumberSystem` `VFXSpawner` `RewardSelectionUI` |

---

## 3. 设计原则与取舍

1. **不在 addon 里硬编码内容。** 所有新机制如有缺口,在 addon 补**通用**实现;具体技能 / 状态 / 装备 /
   房间 / 奖励 / 实体定义都放 `game/demo/phase8/`(内容 `.tres` 或子场景)。出现 `Goblin` / `Fireball`
   这种专有名词就该在 `game/`。
2. **"用进去"= 真实触发 + 断言。** 仅把节点挂进 scene 不算覆盖。每个 slice 必须:
   (a) 场景/内容接好;(b) `_run_auto_loop` 扩展驱动它;(c) 集成测试断言可观察结果(信号 / 状态 / HP / 货币)。
3. **优先复用既有链路,而不是新造机制。** 大量 🟡 类只是没被自动化驱动——先把 `player_input_reader`
   的 command→HFSM→action 链接进 auto-run/集成断言,再补真正缺的内容。
4. **内部数据类随宿主覆盖。** `DomainEvent` `InventorySlot` `DamageRequest` `DialogueRuntime`
   `ContentValidationResult` `RunState` `RoomNode` `RoomGraph` `RewardOption` 这类只在别的类内部出现,
   覆盖其宿主即视为覆盖,不单独"塞进场景"。
5. **两套宏观流程并存的取舍(已定方案 A):**
   phase8 是 **World 流派**(`WorldRouter` + `ZoneDefinition` + `Portal`);
   而 `room/` 一整套(`RunDirector` / `Room*` / `Dungeon*`)+ `loot` 的 `Reward*` + `RewardSelectionUI`
   + `UpgradeDefinition` 属于 **Roguelike 单局流派**。把它塞进村庄叙事并不自然,但已确定**纳入 phase8**:
   - **方案 A(采用):** 在 `field` zone 加一个"试炼洞窟"入口,进入后由 `RunDirector`
     驱动一段 3 房间小 run(复用同一 player + 同一 embedded SceneRouter host 概念),run 结束回 field。
     这样 Roguelike 一组(13 个类)在 phase8 内**自然**覆盖。见 **S6**。
   - ~~方案 B(未采用):从 phase8 豁免、仅靠 `test_run_director` + `test_content_spawn_room_run_integration`
     覆盖~~ —— 已放弃,Roguelike 一组不再豁免,统一在 S6 中真实接入并断言。
6. **终局:phase8 是唯一保留场景。** 每个 slice 不只是"凑覆盖",还要把对应旧 phase 的演示价值接进来
   (见 §4 S11 的 phaseN→slice 对照),这样 S11 删除 phase0–7 时不丢任何演示能力。
   共享资产(`game/demo/entities/`、`game/demo/rooms/`、`game/demo/actions/`)保留复用,不随旧场景删除。

---

## 4. 实施里程碑

每个 slice 体量自包含,可独立提交。标注**新覆盖类**(把该类从 🟡/❌ 抬到 ✅)。

### S0 — 把已有 command→HFSM→action 链接进自动化并断言

**新覆盖(11):** `CommandRouter` `GameCommand` `BuiltinCommands` `CommandReceiver` `StateMachine`
`State` `ActionRunner` `GameAction` `TimedAttackAction` `HitboxComponent` `HurtboxComponent`
(并把 `StatsComponent` 的战斗读取路径、`ActionContext` 一并断言)。

- **改动:** auto-run / 集成不再用裸键或直接 `DealDamageEffect`,改为
  `commands.dispatch(GameCommand.create(BuiltinCommands.MOVE/ATTACK, "player_001", ...))`;
  player 进入 `Move`/`Attack` state,`Attack` state 跑 `TimedAttackAction` 激活 `HitboxComponent`,
  与 `field_beast` 的 `HurtboxComponent` overlap → `CombatResolver` → beast 掉血 → `entity_died`。
- **测试:** `assert` player 收到 MOVE 后位置变化(Move state 生效)、ATTACK 后 hitbox 命中使
  `beast_health.current_hp` 下降、最终 `entity_died`。需 `await get_tree().physics_frame`(碰撞结算)。
- **保留** 现有 `K` 直接 `DealDamageEffect` 作为"脚本伤害"对照路径(已被现有测试覆盖),但 auto-run completion gate 不能靠该 fallback 通过。

### S1 — 技能管线(主动技 + 资源消耗 + 冷却 + 条件 + 命中施加状态)

**新覆盖(11):** `AbilityDefinition` `AbilityInstance` `AbilityController` `CastAction`
`ResourcePoolComponent`(spend)`Condition` `ConditionEvaluator` `CooldownReadyCondition`
`TargetInRangeCondition` `ApplyStatusEffect`(+ 巩固 `ActionContext`)。

- **内容(`game/demo/phase8/`):** `ability.phase8.firebolt` —
  `cost_type="mana"` `cost_amount>0`、`cast_time>0`(走 `CastAction`)、`range>0`、
  `conditions=[CooldownReadyCondition, TargetInRangeCondition]`、
  `effects=[DealDamageEffect, ApplyStatusEffect(status.phase8.burn)]`。
- **player.tscn:** 保持 generic,不默认学习具体 phase ability;`player_input_reader.gd`
  的 `cast_ability_id` 默认为空,由具体 phase scene override。
- **phase8_village_rpg.tscn:** 通过 `Player/Controllers/AbilityController.starting_ability_ids`
  与 `Player/InputReader.cast_ability_id` override 绑定 `ability.phase8.firebolt`。
- **场景:** 新增按键 `F` / auto-run cast 朝 beast;`ResourcePoolComponent.starting_values.mana` 已有。
- **测试:** cast 成功扣 mana、`cooldown_started` 触发、再次 cast 因 `on_cooldown` 失败;
  beast 进/出 `range` 时 `TargetInRangeCondition` 放行/拦截;命中后 beast 持有 `burn` status。

### S2 — 状态效果 + 属性修饰

**新覆盖(8):** `StatusEffectDefinition` `StatusEffectInstance` `StatusEffectController`(driven)
`StatModifier` `StatModifierDefinition` `StatDefinition` `ApplyStatModifierEffect` `LogEffect`。

- **内容:** `status.phase8.burn` — `duration` / `tick_interval`,
  `effects_on_tick=[DealDamageEffect, LogEffect]`,`stat_modifiers=[-defense]`(`StatModifierDefinition`)。
  `StatDefinition` 为 `max_hp/defense/attack_power` 等登记显式定义(供校验/UI)。
- **村庄祝福:** 与 elder 对话新增一条 choice,挂 `ApplyStatModifierEffect`(+attack_power,永久),
  覆盖玩家 buff 路径。
- **测试:** burn 每个 tick 掉血并降 defense(`StatsComponent` 的 modifier 数变化)、duration 到 0 后
  `status_removed` 且 modifier 还原;祝福使 `attack_power` 升高、被 `CombatResolver` 读到。

### S3 — 装备

**新覆盖(1,巩固 `EquipmentController` + `StatModifier`/`ItemInstance` 装备路径):** `EquipmentController`(driven)。

- **内容:** `item.phase8.field_blade`(`equipment_slot="weapon"`,`stat_modifiers=[+attack_power]`),
  由 beast loot 或 shop 提供。
- **场景:** 新增 `E` 装备 / 卸下。
- **测试:** equip 后 `attack_power` 提升并改变战斗伤害;unequip 还原;存档 round-trip(配合 S7)。

### S4 — 数据驱动生成实体

**新覆盖(2):** `EntityDefinition` `EntitySpawner`。

- **内容:** `entity.phase8.field_beast`(`scene_path` 指向现有 `field_beast.tscn`,
  `base_stats` / `starting_ability_ids` / `tags`)。
- **场景:** `field.tscn` 移除静态 `FieldBeast` 实例,改放一个 spawn marker;
  进入 field 时 phase8 用 `EntitySpawner.spawn_entity("entity.phase8.field_beast", root, pos)` 生成。
- **测试:** spawn 出的 beast 具有 definition 的 stats/tags;**`base_overrides` 为空**
  (对齐 `spec/coreview.md` 里 `mark_save_baseline()` 的修复)。

### S5 — 敌人 AI

**新覆盖(3):** `Brain` `SimpleAIEnemyBrain` `Blackboard`。

- **内容/场景:** beast 挂 `SimpleAIEnemyBrain`(用 `Blackboard` 存 target);进入 field 后 beast 主动
  靠近并攻击 player,走 S0 的 hurtbox/combat 链使 **player 掉血**。
- **测试:** player 进入范围后 brain 产生 approach/attack 意图;player `HealthComponent.current_hp`
  因 AI 攻击而下降。

### S6 — 试炼洞窟:Roguelike 单局(见 §3 方案 A)

**新覆盖(11):** `RoomDefinition` `RoomRuntime` `RoomController` `RoomGraph` `RoomNode`
`RunDirector` `RunState` `DungeonGenerator` `RewardSystem` `RewardDefinition` `RewardOption`
`RewardSelectionUI` `UpgradeDefinition`。

- **内容:** 2–3 个 `RoomDefinition` + 对应 room 子场景(各含 `RoomController`);若干 `RewardDefinition`
  (其一携带 `UpgradeDefinition` 永久升级)。
- **场景:** 在 `field` 加 "TrialCave" 交互入口;phase8 持有 `RunDirector` + `RoomRoot` host;
  入口触发 `RunDirector.start_run(seed)` →(`DungeonGenerator` 生成 `RoomGraph`/`RoomNode`,
  `RunState` 跟踪)→ 每间清怪 `on_room_cleared` → `choosing_reward` → `RewardSelectionUI` 选项
  → `RewardSystem.apply_selected` → 下一间;`run_finished("completed")` 回 field。
- **测试:** 跑通 3 房间 run;选 reward 后效果生效(如 upgrade 永久加成);`run_finished` 为 completed。
- **生命周期注意:** 复用同一 player;run 期间 SceneRouter host 与 World host 的切换要参考现有
  `EmbeddedSceneRouter`,避免双重 host 抢占 `scenes` 服务。这是 S6 的主要工程难点,需要专门处理而非回避。

### S7 — 存档协调(场景级 save/load + 组件 round-trip + migration)

**新覆盖(4 抬到 ✅):** `SaveManager`(scene-level)`Saveable` `SaveableComponent`(组件 round-trip)
`SaveMigration`。

- **场景:** 新增 `S`/`L` 存读档,调用 `save.save_game(ServiceRegistry)` / `load_game(...)`;
  覆盖 player 全部 `SaveableComponent`(`HealthComponent` `StatsComponent` `ResourcePoolComponent`
  `StatusEffectController` `AbilityController` `InventoryController` `EquipmentController`)round-trip。
- **migration:** 加一个 `SaveMigration`(version bump 示例)演示旧 payload 升级。
- **测试:** 存→改状态→读后,技能 cooldown/charges、burn status、装备、背包、stats、mana 全部恢复;
  migration 把旧版本字段补齐。可在现有 `test_village_rpg_loop_integration` 的 save 段扩展到组件级。

### S8 — 平台服务钩子(参考 `phase7_platform_slice.gd`)

**新覆盖(8):** `AnalyticsService(+Mock)` `AdService(+Mock)` `IAPService(+Mock)` `CloudSaveService(+Mock)`。

- **analytics:** `quest_turned_in` / `level_up` 时 `track_event(...)`。
- **ads:** player 死亡 → `ads.show_rewarded_ad("revive")` → `rewarded_ad_completed` 回调里 heal 复活。
- **iap:** shop 内"金币包"项 → `iap.purchase("com.mkit.phase8.gold_pack")` → 完成回调 `add_currency`。
- **cloud_save:** 存档后 `cloud_save.save_to_cloud("phase8_profile", data)` / `load_from_cloud(...)`。
- **测试:** 用 `*ServiceMock` 断言收到调用并触发回调(mock 是异步延时,需 `await`)。

### S9 — 表现层 + 运行时工具

**新覆盖(8):** `DamageNumberSystem` `VFXSpawner` `SpawnSceneEffect` `FeedbackSystem` `UIManager`
`DebugOverlay` `ObjectPool` `TimeService`。

- **DamageNumberSystem + VFXSpawner:** 战斗命中飘伤害数字 + spawn 命中 VFX;
  `SpawnSceneEffect` 作为命中/技能的 spawn 特效效果;`ObjectPool` 复用 number/vfx 实例。
- **FeedbackSystem / UIManager:** 统一管理 HUD 面板开关与反馈(toast/shake)。
- **DebugOverlay:** 调试覆盖层显示已注册服务 / 当前 zone / run 状态。
- **TimeService:** 在 demo 层用 `time` 服务驱动计时(替代裸 `delta`),验证其可用。
- **测试:** 命中产生 damage number 节点、pool 复用计数、overlay 列出服务。

### S10 — 收尾:剩余 effect / 交互 / 冲刺

**新覆盖(4):** `InteractionComponent` `AdvanceObjectiveEffect` `CompleteQuestEffect` `DashAction`。

- **InteractionComponent:** player 挂 `InteractionComponent`(Area2D),靠近 elder/portal 自动 `focus`,
  `T`/`R` 改走 `try_interact()`(就近交互),覆盖 `Interactable` focus/unfocus 流程
  (现状是直接 `interact()`)。
- **AdvanceObjectiveEffect / CompleteQuestEffect:** 新增第二条支线任务,用**手动 effect** 推进 + 完成
  (区别于现有"敌死事件自动推进"),覆盖这两个 effect。
- **DashAction:** `Shift` 冲刺 command → dash state/action。
- **测试:** 就近交互成功开对话/传送;手动 effect 推进/完成任务;dash 产生位移。

> S0–S10 全部落地后,§2 矩阵中 🟡 与 ❌ 清零(Roguelike 一组按 §3 方案 A 在 S6 覆盖,零豁免)。

### S11 — 退役旧 demo 场景,收敛到唯一入口

**前置:** S0–S10 已落地且覆盖确认。下表证明 phase0–7 的演示能力已被 phase8 **superset**,删除不丢演示价值。

| 旧场景 | 演示主题 | phase8 中的归属 |
|--------|----------|------------------|
| `phase0_kernel_demo` | kernel 服务 / 引导 | `GameBootstrap`(✅)+ S9(`TimeService`/`ObjectPool`/`DebugOverlay`) |
| `phase1_combat_arena` | 战斗 | S0(command→HFSM→action→hitbox/hurtbox→CombatResolver) |
| `phase2_ability_slice` | 技能 | S1 |
| `phase3_inventory_slice` | 背包 | 现有 ✅(inventory)+ S3(装备) |
| `phase4_run_slice` | roguelike 单局 | S6(复用 `game/demo/rooms/combat_room_*`) |
| `phase5_save_slice` | 存档 | S7 |
| `phase6_experience_slice` | 经验 / 升级 | 现有 ✅(`ExperienceComponent`/`ExperienceCurve`)+ S6(`UpgradeDefinition`) |
| `phase7_platform_slice` | 平台服务(analytics/ads/iap/cloud) | S8 |

**删除清单**(每项含 `.gd` + `.gd.uid` + `.tscn`;`phase7` 另有 `.tscn.uid`):

- `game/demo/phase0_kernel_demo.*` … `game/demo/phase7_platform_slice.*`(0–7 共 8 套)
- `game/demo/bootstrap_phase1.tscn` … `game/demo/bootstrap_phase7.tscn`(7 个引导场景)

**入口收敛:**

- demo 入口统一为 `game/demo/bootstrap_phase8.tscn`。
- `game/demo/bootstrap.tscn` 现 `initial_scene_path` 指向 `phase7_platform_slice.tscn` → **必须**改指
  `phase8_village_rpg.tscn`,或直接删除 `bootstrap.tscn` 改用 `bootstrap_phase8.tscn`。
- 在 `project.godot` 设 `run/main_scene = res://game/demo/bootstrap_phase8.tscn`(当前未设主场景)。
- (可选打磨)把 `phase8_village_rpg.*` 改名去掉 "phase8" 语义(如 `village_rpg_demo.*`)作为 demo 主场景;
  改名要同步 `.uid` 与 `Makefile` 的 `phase8-test` 目标 + `--phase8-auto-run` 参数名。

**保留(共享资产,phase8 / S6 复用,勿删):**

- `game/demo/entities/`(`player` 必留;`enemy` / `dummy` 供 S0 / S5 / S6 复用)
- `game/demo/rooms/combat_room_0{1,2}.tscn`(S6 试炼洞窟复用)
- `game/demo/actions/demo_wait_action.gd`(若 S6 房间用到则留;否则审计后单独删)

**收尾:** 删除后 grep 残留引用(`docs/`、`spec/`、其余 `.tscn`)并更新;`make ut` + `make phase8-test` 全绿。

---

## 5. 测试与运行组织

- **主集成测试:** 扩展 `test/integration/test_village_rpg_loop_integration.gd`,或新建
  `test/integration/test_scene8_full_tour_integration.gd`,逐 slice 断言;
  命名沿用 `test_tc_int_scene8_<nn>_<desc>`。优先复用 `int_test_helpers.gd` 的 `make_*`/`add_*` 工厂。
- **headless auto-run:** 扩展 `phase8_village_rpg.gd::_run_auto_loop`,把每个新 slice 编进自动序列,
  `--phase8-auto-run` 跑通后 `_phase8_loop_complete()` 校验并 `quit(0)`。
- **单元测试:** 每个 slice 复用 / 补对应单元测试(已有 `test_ability_controller`、`test_run_director`、
  `test_reward_system`、`test_saveable_components` 等);新机制若在 addon 补了通用实现,必须配单元测试。
- **物理帧:** 涉及 `Hitbox/Hurtbox` 的断言要 `await get_tree().physics_frame`(碰撞在物理帧结算)。
- **服务清理:** 集成测试 `after_each()` 调 `IntTestHelpers.cleanup_service_registry()`;注意
  `ServiceRegistry.clear()` 不会移除 bootstrap 加进去的子节点(见既有集成测试陷阱)。

运行命令:

```bash
make ut                                   # 全套(kernel + modules + integration via GUT)
make ut-modules
$GODOT --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://test/integration/test_scene8_full_tour_integration.gd -gexit
# 交互/headless 跑 demo 本体:
$GODOT game/demo/bootstrap_phase8.tscn -- --phase8-auto-run
```

---

## 6. 完成定义(Definition of Done)

- §2 覆盖矩阵的 🟡 / ❌ 清零;无法/不值得纳入 phase8 的类进入"显式豁免"表并写明理由。
- `make ut` 全绿;贴真实结果(脚本数 / 测试数 / 断言数)。
- `--phase8-auto-run` headless 跑通并 `quit(0)`,`_phase8_loop_complete()` 通过;completion gate 必须覆盖 command combat kill、firebolt cast、burn tick 和 `phase8_burn_tick` LogEffect。
- 新建 `.gd` 都生成并提交 `.uid`(跑一次 `make ut` 让 Godot 写入,勿手写 UID)。
- 改了公共接口的类同步更新 `docs/ref/<ClassName>.md` 及相关 layer/pipeline 文档(中文概念段保持中文)。
- 无 `game → addon` 反向依赖;无具体内容硬编码进 `addons/mkit/`(新机制缺口在 addon 补通用实现,
  内容放 `game/demo/phase8/`)。
- **S11 后:** `game/demo/` 下仅剩 phase8 一个 demo 场景 + 单一入口;phase0–7 及其 `bootstrap_phaseN`
  已删除;`bootstrap.tscn` / `project.godot` 主场景指向 phase8;全仓库无指向已删场景的悬挂引用。

---

## 7. 风险与显式豁免

- **物理碰撞 headless 结算**(S0/S5):需在断言前 `await physics_frame`,且为 `Hitbox/Hurtbox` 配好
  `CollisionShape2D` 与 layer/mask(player.tscn/beast.tscn 已各带一个 shape,需确认 layer 对位)。
- **World 与 Run 双流程共存**(S6):两套都想抢 `scenes` 服务 / host;按 §3 方案 A 谨慎处理
  (run 期间临时接管 host,run 结束归还 World 流程),这是必须啃下来的工程项。
- **mock 异步回调**(S8):`*ServiceMock` 用延时回调,集成测试要 `await` 到回调到达再断言。
- **体量:** S0–S10 是一条较长的路。建议按 slice 分多次提交;若只想先拿到"绝大多数类覆盖",
  优先级 **S0 → S1 → S2 → S3 → S7 → S8**(纯 RPG 主线 + 存档 + 平台),把 **S4/S5/S6/S9/S10**
  作为第二批。
- **显式豁免:** 无。已决定不豁免任何模块类——Roguelike 一组在 S6 真实接入 phase8 并断言。

---

## 8. 附录:slice → 新覆盖类映射

| slice | 新覆盖类 |
|-------|----------|
| S0 | CommandRouter, GameCommand, BuiltinCommands, CommandReceiver, StateMachine, State, ActionRunner, GameAction, TimedAttackAction, HitboxComponent, HurtboxComponent (+ StatsComponent 战斗读取, ActionContext) |
| S1 | AbilityDefinition, AbilityInstance, AbilityController, CastAction, ResourcePoolComponent, Condition, ConditionEvaluator, CooldownReadyCondition, TargetInRangeCondition, ApplyStatusEffect |
| S2 | StatusEffectDefinition, StatusEffectInstance, StatusEffectController, StatModifier, StatModifierDefinition, StatDefinition, ApplyStatModifierEffect, LogEffect |
| S3 | EquipmentController |
| S4 | EntityDefinition, EntitySpawner |
| S5 | Brain, SimpleAIEnemyBrain, Blackboard |
| S6 | RoomDefinition, RoomRuntime, RoomController, RoomGraph, RoomNode, RunDirector, RunState, DungeonGenerator, RewardSystem, RewardDefinition, RewardOption, RewardSelectionUI, UpgradeDefinition |
| S7 | SaveManager, Saveable, SaveableComponent, SaveMigration |
| S8 | AnalyticsService(+Mock), AdService(+Mock), IAPService(+Mock), CloudSaveService(+Mock) |
| S9 | DamageNumberSystem, VFXSpawner, SpawnSceneEffect, FeedbackSystem, UIManager, DebugOverlay, ObjectPool, TimeService |
| S10 | InteractionComponent, AdvanceObjectiveEffect, CompleteQuestEffect, DashAction |

随宿主自动覆盖、无需单列:`DomainEvent` `InventorySlot` `DamageRequest` `DialogueRuntime`
`ContentValidationResult` `RunState` `RoomNode` `RoomGraph` `RewardOption`(已在上表宿主 slice 内出现)。
