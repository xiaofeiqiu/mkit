# mkit 大改版阶段 0 跟踪（启动）

## 1. 当前阶段

- 目标：阶段 5（收口与发布）
- 状态：阶段5进行中（2026-06-07）
- 开始时间：2026-06-07
- 说明：阶段0~4均通过，当前进入阶段5收口（兼容层收口、文档收口、发布清单）。
- 阶段0验收：通过
- 阶段1验收：通过
- 阶段2验收：通过
- 阶段3验收：通过（M3）
- 阶段4验收：通过

## 2. 启动任务（阶段3后阶段性状态）

- [x] 新建阶段 0 跟踪页。
- [x] 完成服务关系图（文本 + spec）。
- [x] 完成 `ServiceRegistry`/`GameBootstrap` 服务基线清单。
- [x] 完成模块边界清单（含 owner/consumer 依赖关系）。
- [x] 补充阶段 0 迁移决议文档（明确哪些调用下个阶段处理）。
- [x] 记录阶段 0 后的验收风险与回滚点。

## 1.1 阶段1启动项（完成）

- [x] 新增 `addons/mkit/kernel/runtime/mkit_runtime_context.gd`（typed runtime context）
- [x] `ServiceRegistry` 新增 runtime context 挂接与 `get_port/get_port_ids` 兼容入口
- [x] `GameBootstrap` 在启动时构建并注入 runtime context，启动日志输出服务端口清单
- [x] 阶段1第一批迁移：把 `combat`、`shop`、`world` 高频服务调用切换为 `ServiceRegistry.get_port(...)`（不移除字符串兼容）
- [x] 阶段1第二批迁移：把 `dialogue`、`quest`、`inventory`、`progression` 高频服务调用切换为 `ServiceRegistry.get_port(...)`
- [x] 阶段1第三批迁移：将剩余 kernel/ai/combat/world/loot/ui/entity 的服务访问切换为 `ServiceRegistry.get_port(...)`（兼容层保留）
- [x] 阶段2启动项：`EventService`、`CommandReceiver`、`EntitySpawner`、`AI/Brain`、`QuestService`、`World Dungeon RoomController`、`DebugOverlay` 使用 `EntityContract` 进行实体节点访问
- [x] 阶段2补充：`TimedAttackAction`/`CastAction` 改为 `EntityContract` 查找动画与组件入口，进一步减少硬编码路径。
- [x] 阶段2验收项：`EntityContract` 增补缺失节点提示（深层查找缺失时给出 `push_warning`），并同步用于核心读写路径。

## 3. 阶段 3 验收闭环（M3）

### 3.1 战斗域

- [x] 三阶段模型已落地：
  - `addons/mkit/modules/combat/damage_intent.gd`
  - `addons/mkit/modules/combat/damage_resolution.gd`
  - `addons/mkit/modules/combat/damage_application.gd`
- [x] `addons/mkit/modules/combat/combat_service.gd` 重构为：
  - `resolve_damage_intent`
  - `resolve_damage_resolution`
  - `to_application`
  - `resolve()` 统一返回 `DamageResult`
- [x] `HealthComponent.apply_damage()` 与状态控制器消费统一 `DamageResult`（`applied_status_effects` + `status_applications`）。
- [x] 战斗链路覆盖：`test/unit/modules/test_combat_service.gd`（01~17）覆盖命中/暴击/规避/状态挂载与 trace。

### 3.2 事件与状态变更

- [x] `EventService` 公开事件由 `emit_domain_event(...)` 统一构造 `DomainEvent`。
- [x] 高频信号保留并继续兼容：`damage_applied`、`entity_died`、`inventory_changed`、`quest_*` 等。
- [x] 订阅意图清单（当前公开路径）：
  - `QuestService`：`domain_event_emitted`（任务推进）与 `entity_died`（合成 `enemy_killed`）
  - `RoomController`：`entity_died`（房间清场）
  - `RunDirector`：`entity_died`（run 生命周期）
  - `FeedbackSystem`：`damage_applied`、`entity_died`（表现层反馈）
  - `InventoryController`：`inventory_changed`（背包变更）

### 3.3 数值与资源模型

- [x] `ResourceSet` 接入 `ResourcePoolComponent`，统一当前值/上限处理与序列化中间模型。
- [x] `Wallet` 接入 `ProgressionState`，统一货币边界并避免裸字典操作散落。
- [x] `ProgressionState.to_save_data()` 与 `from_save_data()` 保持 `currencies` 字段兼容旧存档。

## 4a. 阶段 4 验收闭环（M4）

- [x] 新增 `save_scope` 与 scope 注册接口定义（至少含 run / room / reward）。
- [x] `SaveService` 能在无完整场景树下恢复 `world` 关键状态（run 进度与房间状态）。
- [x] 世界 run 完整闭环通过（入场）。
- [x] 世界 run 完整闭环通过（战斗）。
- [x] 世界 run 完整闭环通过（奖励分派）。
- [x] 兼容层保持：新存储同时写 `payload`，现有读取路径不回归。
- [x] 迁移链验证：至少新增 1 条从旧结构到新结构的读兼容路径并有回归测试。

## 4. 阶段 0 基线（当前拍照）

### 3.1 ServiceRegistry 常量清单（源码源头）

- `events`
- `content`
- `random`
- `time`
- `actions`
- `effects`
- `commands`
- `combat`
- `scenes`
- `pool`
- `save`
- `progression`
- `analytics`
- `ads`
- `iap`
- `cloud_save`
- `quest`
- `shop`
- `audio`
- `dialogue`
- `world`
- `loot`

### 3.2 GameBootstrap 当前服务注册顺序（源码源头）

1. `events`
2. `content`
3. `random`
4. `time`
5. `actions`
6. `effects`
7. `commands`
8. `combat`
9. `scenes`
10. `pool`
11. `save`
12. `progression`
13. `analytics`
14. `ads`
15. `iap`
16. `cloud_save`
17. `quest`
18. `shop`
19. `audio`
20. `dialogue`
21. `world`
22. `loot`

### 3.3 模块目录（当前）

`addons/mkit/modules/`

- ai
- combat
- dialogue
- entity
- interaction
- inventory
- loot
- progression
- quest
- shop
- ui
- world

## 4.4 模块 -> 服务“拥有者/消费者”关系图（阶段 0）

### Owner（服务提供侧）
- `events`：`addons/mkit/kernel/events`
- `content`：`addons/mkit/kernel/content`
- `random`：`addons/mkit/kernel/random`
- `time`：`addons/mkit/kernel/time`
- `actions`：`addons/mkit/kernel/actions`
- `effects`：`addons/mkit/kernel/effects`
- `commands`：`addons/mkit/kernel/commands`
- `combat`：`addons/mkit/modules/combat`
- `scenes`：`addons/mkit/kernel/scenes`
- `pool`：`addons/mkit/kernel/services/pool_service.gd`
- `save`：`addons/mkit/kernel/save`
- `progression`：`addons/mkit/modules/progression`
- `analytics`：`addons/mkit/kernel/platform/analytics`
- `ads`：`addons/mkit/kernel/platform/ads`
- `iap`：`addons/mkit/kernel/platform/iap`
- `cloud_save`：`addons/mkit/kernel/platform/cloud_save`
- `quest`：`addons/mkit/modules/quest`
- `shop`：`addons/mkit/modules/shop`
- `audio`：`addons/mkit/kernel/services/audio_service.gd`
- `dialogue`：`addons/mkit/modules/dialogue`
- `world`：`addons/mkit/modules/world`
- `loot`：`addons/mkit/modules/loot`

### Consumer（按模块）
- `addons/mkit/kernel/debug` → `events`, `debug`
- `addons/mkit/kernel/actions` → `effects`
- `addons/mkit/kernel/commands` → `time`
- `addons/mkit/kernel/effects/builtin/spawn_scene_effect` → `pool`
- `addons/mkit/modules/ai` → `commands`
- `addons/mkit/modules/combat/combat_service` → `random`
- `addons/mkit/modules/combat/abilities/ability_controller` → `content`, `actions`
- `addons/mkit/modules/combat/health/health_component` → `events`
- `addons/mkit/modules/combat/status_effects/status_effect_controller` → `content`, `effects`
- `addons/mkit/modules/combat/hitbox_component` → `combat`
- `addons/mkit/modules/combat/damage/deal_damage_effect` → `combat`
- `addons/mkit/modules/combat/`（其他）→ `content`
- `addons/mkit/modules/dialogue/dialogue_service` → `content`, `effects`, `events`
- `addons/mkit/modules/dialogue/dialogue_interactable` → `dialogue`, `events`
- `addons/mkit/modules/entity/entity_spawner` → `content`
- `addons/mkit/modules/inventory/equipment_controller` → `content`
- `addons/mkit/modules/inventory/inventory_controller` → `content`, `events`
- `addons/mkit/modules/inventory/`（其他）→ `content`
- `addons/mkit/modules/loot/loot_service` → `content`, `random`
- `addons/mkit/modules/loot/reward_system` → `content`, `effects`, `events`, `random`
- `addons/mkit/modules/progression/progression_service` → `content`, `effects`
- `addons/mkit/modules/progression/add_currency_effect` → `progression`
- `addons/mkit/modules/progression/spend_currency_effect` → `progression`
- `addons/mkit/modules/quest/quest_service` → `content`, `effects`, `events`
- `addons/mkit/modules/quest/accept_quest_effect` → `quest`
- `addons/mkit/modules/quest/advance_objective_effect` → `quest`
- `addons/mkit/modules/quest/complete_quest_effect` → `quest`
- `addons/mkit/modules/shop/shop_service` → `content`, `effects`, `events`
- `addons/mkit/modules/ui/feedback_system` → `events`
- `addons/mkit/modules/ui/ui_manager` → `time`, `ui`
- `addons/mkit/modules/ui/reward_selection_ui` → `ui`
- `addons/mkit/modules/ui/vfx_spawner` → `pool`
- `addons/mkit/modules/ui/damage_number_system` → `pool`
- `addons/mkit/modules/world/world_service` → `content`, `scenes`, `events`, `audio`
- `addons/mkit/modules/world/dungeon/room_loader` → `content`
- `addons/mkit/modules/world/dungeon/room_controller` → `content`, `events`, `loot`
- `addons/mkit/modules/world/dungeon/reward_coordinator` → `loot`
- `addons/mkit/modules/world/dungeon/run_director` → `events`, `random`
- `addons/mkit/modules/world/portal` → `world`
## 4.5 模块边界清单（服务依赖分类）

- 纯业务规则/服务：`combat`, `quest`, `shop`, `world`, `dialogue`, `progression`, `loot`
- 工具型/呈现/场景服务：`ui`, `entity`, `interaction`, `ai`
- 外围平台/适配：`analytics`, `ads`, `iap`, `cloud_save`, `audio`

## 5. 阶段0 风险与决策（更新）

- 已确认核心服务字符串 key 全部存在并在阶段1优先统一替换的范围内。
- 需要第一优先替换：核心服务访问点（按 rg 命中密度）：
  - `content`, `events`, `effects`, `actions`, `random`, `scenes`, `pool`
- 可接受兼容行为但需记录：
  - 仅保留启动与自注册场景的字符串服务检查（如 `debug` 自注册、`ui` 自注册、核心 world/事件存在性检查）
  - 所有高频业务模块已完成本阶段服务端口替换；阶段1结束前只保留兼容入口实现。
- 迁移决议（阶段1优先级）：
  - 先改造：`events`, `content`, `combat`, `effects`, `actions`, `random`
  - 再改造：`pool`, `scenes`, `world`, `ui`, `quest`, `shop`, `dialogue`
  - 后置改造：`loot`, `progression`, `save`, `audio`, `analytics/ads/iap/cloud_save`
- 回滚点：
  - 阶段0只涉及文档；回滚即回到此前 commit 的 spec 版本
  - 阶段1如引入 typed 访问失败，先停用新接口并保留 `ServiceRegistry` 字符串路径

## 6. 依赖梳理记录（待补）

- 当前阶段不改代码，先建立“声明点”和“调用点”映射后再决策迁移顺序。
- 重点检查项（下阶段优先）：
  - combat 依赖：`random / actions / effects / content / events`
  - inventory 依赖：`content / events`
  - quest 依赖：`content / effects / events`
  - world 依赖：`content / scenes / events / audio / loot`
  - shop 依赖：`content / progression / effects / events`

## 7. 阶段5执行（阶段 4 → 阶段 5）

- 阶段4验收闭环：完成 `save_scope` 注册协议并挂接 `SaveService`。
- 阶段4验收闭环：完成世界 run 的持久化恢复路径（场景缺失可恢复、奖励状态可恢复）。
- 阶段4验收闭环：完成 `test_run_director.gd` + `test_scene8` 的恢复回归。
- 阶段5启动条件：阶段4验收 4 项全部通过，已满足。
- 阶段5启动条件：开始执行文档与迁移、日志模板、错误码策略收口与发布清单。

## 7a. 阶段 5 收口清单（进行中）

- [x] 兼容层剩余冗余调用点清单已冻结（不再新增）。
- [x] 兼容层可见冗余清理：`get_port("...")` 只保留标准常量入口，新增 `SERVICE_UI` 并替换直接 `ui` 字符串调用。
- [x] 错误码与日志模板升级说明已出稿：`docs/error_reporting.md`（新增、弃用、迁移提示模板）。
- [x] 对 `docs/ref` 与 `docs/` 的对齐清单已固定版本号并同步：`docs/phase5_migration_and_release_checklist.md`（版本 2026-06-07）。
- [ ] 发布前发布清单将包含：`make ut`, `make int`, `make docs-check` 的执行证据（未执行前需补齐）。

### 7a.1 阶段 5 交付收口（与 impl plan 对齐）

- [ ] 阶段 5 合并清单最终确认：`spec/implementation-plan.md` 第五阶段与本页一致后打勾。
- [ ] 阶段 5 发布前清单闭环：补齐 `make ut` / `make int` / `make docs-check` 的实际执行结果与失败清单。
- [ ] 阶段 0~4 与阶段 5 的验收勾稽：每阶段验收项与实际测试证据逐项映射（含时间戳）。
- [ ] 如有 `game/` 与 `addons/mkit/` 职责边界新增偏差，先行修正后再允许闭环确认。

### 7a.1a 阶段5执行证据（需按次序补齐）

- 目标 1：补充 `make ut` 与 `make int` 执行记录  
  - [ ] 记录执行命令与时间（`date -u`）
  - [ ] 记录 `make ut` 结果（通过/失败数、失败清单）
  - [ ] 记录 `make int` 结果（通过/失败数、失败清单）
  - [ ] 失败项分类（`combat` / `save` / `world` / `ui` / `shop` / `quest` / `dialogue` / `bootstrap`）
  - [ ] 关键失败的最小修复决策点

- 目标 2：补充文档门禁执行记录  
  - [ ] 记录 `make docs-check` 命令与时间
  - [ ] 记录 `make docs-check` 结果与新增警告/错误
  - [ ] 关联到具体文档文件（含 `docs/ref/*`、`spec/*`）

- 目标 3：生成阶段性收口快照  
  - [ ] 在本页添加阶段 5.0 收口时间戳（UTC）
  - [ ] 在本页添加“是否可进入发布判定”结论（是 / 否）
  - [ ] 若为“否”，附上阻塞项与下一步修复优先级

### 7a.2 阶段 5 快照与执行证据（2026-06-07）

- [x] `make ut` 最近一次执行完成（结果已知）
  - 命令：`make ut`
  - 时间：2026-06-07（本地记录）
  - 结果：`202 passed / 202`（通过）
  - 备注：此前为修复类型推断阻塞所做脚本修补后，单测回归全部通过。

- [ ] `make int` 最近一次执行完成（待补齐到阶段记录页）
  - 命令：`make int`
  - 时间：待补充
  - 结果：待补充（上次运行见 35/46 通过，11 个失败）
  - 失败分类：`combat`、`dialogue`、`quest`、`world`、`shop`、`bootstrap`、`village_loop`
  - 关键阻塞：`TimedAttackAction` `hitbox_path` 兼容性修复后建议重跑复核是否降级

- [ ] `make docs-check` 执行补齐
  - 命令：`make docs-check`
  - 时间：待补充
  - 结果：待补充
  - 备注：无稳定执行记录前不许关闭阶段5收口

- [ ] 阶段 5 进入发布判定
  - 结论：否（阻塞条件未完全闭环）
  - 需补齐：`make int` 全绿或明确残留风险清单 + `make docs-check` 结果

### 7b. 阶段5继续闭环（按优先级）

- [ ] P0：补齐 `make int` 全量结果（含失败用例与堆栈）后，先修复场景8链路回归点。
- [ ] P1：修复 `world`、`quest`、`dialogue`、`shop`、`village_loop` 断言漂移，确认是否与 `SaveService`/`Currency / Wallet` 边界变更相关。
- [ ] P2：补齐 `make int` 门禁后再执行 `make docs-check`，同步把文档警告与错误写入 7a.1a 证据。
- [ ] P3：阶段5发布前最终签署：`make ut` 全绿 + `make int` 全绿 + `make docs-check` 全绿后，才允许关闭 5a/5b 门禁。

### 7c. 证据日志（按时间追加）

- [ ] Run A（2026-06-07）
  - `make ut`：
    - 日期：
    - 结果：
    - 失败用例：
  - `make int`：
    - 日期：
    - 结果：
    - 失败用例：
  - `make docs-check`：
    - 日期：
    - 结果：
    - 警告/错误：
  - 发布判定结论：
    - 是 / 否
    - 否时阻塞项：

### 7d. 阶段5失败域修复映射（P0~P2）

- [ ] P0A 场景8链路（最高优先）
  - 已知症状：`Invalid assignment of property or key 'hitbox_path' on TimedAttackAction` 为主因导致场景8测试链条连锁失败。
  - 直接动作：统一检查 `TimedAttackAction` 的兼容字段与场景状态脚本 `action.hitbox_path` 写入路径的一致性（优先兼容，不破坏历史调用）。
  - 验收指标：`test_scene8_full_tour_integration.gd` 场景8主链路通过，后续 world 与循环调用失败项同步消退。

- [ ] P0B 启动/引导闭环
  - 已知症状：`test_runtime_bootstrap_integration` 在服务注册、幂等加载与场景重进行为存在断言偏差。
  - 直接动作：核对 `GameBootstrap` 注册顺序清单与实际 `ServiceRegistry` 端口快照、`save_path` 分支行为。
  - 验收指标：`boot registers all services`、`bootstrap idempotency` 相关测试通过。

- [ ] P1A 世界流转
  - 已知症状：`test_world_pipeline_integration`、`test_village_rpg_loop_integration` 在世界进度、关卡转移与回合触发上出现偏差。
  - 直接动作：核对 `run_director / room_controller / world_service / progression` 之间事件与持久化边界是否被改动破坏。
  - 验收指标：run 生命周期与世界状态恢复用例通过，village loop 不再出现重复/缺失切入。

- [ ] P1B 任务与对话资产
  - 已知症状：`test_dialogue_pipeline_integration`、`test_quest_pipeline_integration` 货币与任务推进数值断言异常。
  - 直接动作：核对 `QuestService` 与 `DialogueService` 对 `currency_changed`、`reward`、`Objective` 事件与存档快照的字段协议。
  - 验收指标：`currency_changed` 与任务完成奖励链路断言恢复一致。

- [ ] P1C 商店与货币域
  - 已知症状：`test_shop_pipeline_integration` 库存、货币和物品 id 断言漂移。
  - 直接动作：核对 `ShopService` 与 `ProgressionService/Wallet` 的 `currency` 字段来源、消费返回值与事件发布。
  - 验收指标：商品购买/失败回退与库存变化用例通过。

- [ ] P2 证据闭环
  - 已知症状：`make int` 仍有多域未闭环，`make docs-check` 未执行补齐证据。
  - 直接动作：完成 `make int` 全量复测后，填充 7a.2 与 7c 证据项并进行风险签署。
  - 验收指标：`make int` 全绿且三类门禁日志齐全后，可执行阶段5发布判定。

### 7a.2 关键决策约束（继续执行）

- 若 `make int` 未通过，但改动仅在 `addons/mkit`，则先执行收口最小修复（兼容路径 / 服务边界 / 事件 payload）；
- 若失败源于 `game/` 内容依赖变更，先改 `game/` 过渡接入后再收口；
- 任何阶段都不得新增 `addons/mkit` 对 `game/` 的直接内容依赖；该项一旦触发则自动回退到兼容修复路径。

### 7a.3 启动阶段与验收阶段同步说明

- 阶段 0 已建立：启动时冻结范围、形成基线与关系图、完成阶段 0 迁移决议。
- 阶段验收默认定义：只有在验收页与实现页（`spec/implementation-plan.md`）都打勾且文档一致时，阶段才算“通过”。
- [ ] 阶段5收尾门禁：回归风险单、回滚演练记录、兼容路径保留到最后一个提交（待登记回归记录）。

## 8. 阶段5验收闭环（进行中）

- [ ] 运行时启动与典型 gameplay 流程在不依赖兼容层前提下通过。
- [ ] 关键 public API 与 docs 完全对齐并通过 `make docs-check`。
- [ ] `make ut`、`make int`、`make docs-check` 证据链全部记录在该收口文件。
- [ ] 回滚预案与发布清单齐备（含回归风险、恢复步骤、保底验证）。

## 7b. 阶段5发布前清单（草案）

清单文件：`docs/phase5_migration_and_release_checklist.md`（版本：2026-06-07）

- [ ] 运行时验收：`make demo-test`（启动 + 启动时序 + 兼容路径观察）
- [ ] 典型 gameplay 验证：三房间 run 完整闭环（可用现有 demo/或集成脚本）
- [ ] 回归：`make ut` + `make int`
- [ ] 文档校验：`make docs-check`
- [ ] 回滚演练：回退到阶段4最后稳定提交并验证启动

## 9. 阶段0验收预检（已留档）

- [x] 基线服务常量清单完整（与 `ServiceRegistry` 一致）
- [x] 基线服务注册顺序已落账（与 `GameBootstrap` 一致）
- [x] 模块目录与消费者清单已落账
- [x] 形成 owner/consumer 关系图（当前已落账，需复核服务 owner 文件路径）
- [x] 阶段0迁移决议闭环完成
- [x] 风险与回滚点补齐并签字
- [x] 阶段1第三批迁移项完成（kernel/ai/world/loot/ui/entity/combat 段）
