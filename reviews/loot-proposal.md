# Proposal：死亡掉落规则从 EntityDefinition 移到 Loot 模块

> 日期：2026-06-11
> 决策：采用“更干净的方案”，删除 `EntityDefinition.loot_table_id`，用 loot 模块自己的规则资源描述“哪些实体死亡时 roll 哪些掉落表”。

## 目标

敌人死亡掉落要保留 mkit 的可复用性，但不能把具体玩法链路塞进 `entity` 或 `combat` 模块。

目标边界：

- `HealthComponent` 只负责生命值、死亡状态和死亡事件。
- `EntityDefinition` 只负责实体生成所需的身份、场景、阵营、标签、属性和初始技能。
- `LootService` 继续只负责按 `LootTableDefinition` roll 出 `LootRollResult`。
- 新增 loot 模块内的死亡掉落桥接层，负责把 `CombatEvents.ENTITY_DIED` 转成 `LootEvents.LOOT_DROPPED`。
- 游戏代码负责最终交付：进背包、掉到地上、弹 UI、播放特效，或忽略。

非目标：

- 不让 `HealthComponent` 直接调用 `LootService`。
- 不让 `EntitySpawner` 或 `EntityDefinition` 依赖 loot 模块。
- 不在 addon 里硬编码“敌人掉材料后进玩家背包”这种具体规则。
- 不保留 `EntityDefinition.loot_table_id` 作为兼容字段。

## 当前事实

当前代码已经具备所需基础：

- `HealthComponent.die(killer)` 会发 `CombatEvents.entity_died(...)`，并在 `destroy_on_death` 的 `queue_free()` 前发出。
- `CombatEvents.entity_died()` payload 已包含死亡实体的 `entity_id`、`entity_ref`、`definition_id`、`faction`、`tags`。
- `LootService.roll_table(table_id, context)` 已能从 `ContentService` 查 `LootTableDefinition` 并返回 `LootRollResult`。
- `ContentService.get_all_by_type(type_name)` 已支持按 class_name 枚举资源，适合查找规则资源。
- demo 现在是在 `game/village_rpg_demo.gd` 中订阅死亡事件后手动 roll 固定 loot 表；这应迁移为“mkit roll，game 交付”。

## Proposal

### 1. 删除 `EntityDefinition.loot_table_id`

`EntityDefinition` 不再暴露掉落表字段。

原因：

- entity 模块不应该知道 loot 模块。
- 一个实体可能有多个掉落规则：按难度、区域、击杀者、任务状态、tag、事件条件决定。
- 把掉落表挂在实体定义上，会把“实体是什么”和“死亡奖励怎么结算”混在一起。

删除范围：

- `addons/mkit/modules/entity/entity_definition.gd`
- demo content 中 `EntityDefinition` 资源上的 `loot_table_id`
- docs/generated API
- cookbook 07 的 `EntityDefinition` 字段参考
- cookbook 08 的死亡掉落示例
- 相关 integration/unit tests

### 2. 新增 `DeathLootRuleDefinition`

路径建议：

```text
addons/mkit/modules/loot/death_loot_rule_definition.gd
```

职责：描述“一个死亡事件是否匹配，以及匹配后 roll 哪些 loot table”。

建议字段：

```gdscript
class_name DeathLootRuleDefinition
extends ContentDefinition

@export var rule_id: String = ""
@export var enabled: bool = true
@export var priority: int = 0
@export var entity_definition_ids: Array[String] = []
@export var factions: Array[String] = []
@export var required_tags: Array[String] = []
@export var excluded_tags: Array[String] = []
@export var conditions: Array[Condition] = []
@export var loot_table_ids: Array[String] = []
@export var stop_after_match: bool = false
```

字段语义：

| 字段 | 语义 |
|------|------|
| `rule_id` | ContentService 注册用 id |
| `enabled` | 关闭后规则不参与匹配 |
| `priority` | 多规则匹配时的排序，高优先级先处理 |
| `entity_definition_ids` | 非空时只匹配这些 `EntityIdentity.definition_id` |
| `factions` | 非空时只匹配这些死亡实体阵营 |
| `required_tags` | 非空时死亡实体必须包含全部 tag |
| `excluded_tags` | 非空时死亡实体包含任一 tag 则排除 |
| `conditions` | 额外条件；用死亡上下文执行 |
| `loot_table_ids` | 匹配后依次 roll 的 `LootTableDefinition` id |
| `stop_after_match` | 本规则匹配后停止处理后续规则 |

规则资源属于 loot 模块，所以 entity 模块保持干净。

### 3. 新增 `DeathLootService`

路径建议：

```text
addons/mkit/modules/loot/death_loot_service.gd
```

职责：

1. 监听 `CombatEvents.ENTITY_DIED`。
2. 从事件 payload 读取死亡实体的 `definition_id` / `faction` / `tags`。
3. 从 `ContentService.get_all_by_type("DeathLootRuleDefinition")` 获取规则。
4. 按 `priority` 排序并匹配规则。
5. 对匹配规则的 `loot_table_ids` 调 `Mkit.loot().roll_table(...)`。
6. 每个非空 roll 结果发 `LootEvents.LOOT_DROPPED`。
7. 不负责把物品放入背包或实例化地面 pickup。

服务注册建议：

```gdscript
services[DeathLootService.SERVICE_ID] = DeathLootService.new()
```

`DeathLootService` 是 Node 服务，因为它需要订阅事件并随 ServiceRegistry 生命周期断开。

### 4. 新增 loot 事件和 typed drop carrier

新增：

```text
addons/mkit/modules/loot/loot_events.gd
addons/mkit/modules/loot/loot_drop_result.gd
```

`LootDropResult` 建议字段：

```gdscript
class_name LootDropResult
extends RefCounted

var rule_id: String = ""
var loot_table_id: String = ""
var entity_id: String = ""
var entity_definition_id: String = ""
var entity_ref: Node = null
var killer_id: String = ""
var killer_ref: Node = null
var roll_result: LootRollResult = null
```

`LootEvents.loot_dropped(drop: LootDropResult)` 用 `DomainEvent` 承载这个 typed object：

```gdscript
DomainEvent.create(LOOT_DROPPED, drop.entity_id, drop.killer_id, {"drop": drop})
```

这样对外 API 不需要暴露一堆松散 Dictionary key；需要时仍可从 `drop.roll_result.item_instances` 读到已 roll 好的物品。

### 5. 死亡上下文语义

`HealthComponent.die(killer)` 现在已经接收 `killer`，但 `CombatEvents.entity_died()` 没把 killer 写进 payload。应补齐：

```gdscript
static func entity_died(entity_id: String, entity_ref: Node, killer_ref: Node = null) -> DomainEvent
```

payload 新增：

- `killer_ref`
- `killer_id`
- `killer_definition_id`
- `killer_faction`
- `killer_tags`

`DeathLootService` 构造 roll context：

```gdscript
var ctx := GameplayContext.new()
ctx.source = killer_ref if killer_ref != null else entity_ref
ctx.target = entity_ref
ctx.payload["death_entity_id"] = entity_id
ctx.payload["death_definition_id"] = definition_id
ctx.payload["killer_id"] = killer_id
ctx.payload["rule_id"] = rule.rule_id
ctx.payload["loot_table_id"] = table_id
```

这样 `LootEntry.conditions` 可以按击杀者、死亡实体、区域、难度等自定义 payload 过滤。

### 6. 游戏侧交付示例

mkit 只发事件：

```text
entity_died -> DeathLootService -> loot_dropped
```

游戏决定如何交付：

```gdscript
func _ready() -> void:
    Mkit.events().subscribe(LootEvents.LOOT_DROPPED, _on_loot_dropped)


func _on_loot_dropped(event: DomainEvent) -> void:
    var drop := event.payload.get("drop") as LootDropResult
    if drop == null or drop.roll_result == null:
        return
    var inventory := EntityContract.get_controller(_player, "InventoryController") as InventoryController
    if inventory == null:
        return
    for item in drop.roll_result.item_instances:
        inventory.add_item(item)
```

如果游戏要地面掉落，则同一个事件可以 spawn pickup scene，而不是入背包。

### 7. 示例资源

替代旧的 `EntityDefinition.loot_table_id`：

```gdscript
var rule := DeathLootRuleDefinition.new()
rule.rule_id = "death_loot.field_beast"
rule.entity_definition_ids = ["entity.demo.field_beast"]
rule.loot_table_ids = ["loot.demo.field_beast", "loot.demo.field_blade"]
```

或者按 tag：

```gdscript
rule.rule_id = "death_loot.beasts"
rule.factions = ["enemy"]
rule.required_tags = ["beast"]
rule.loot_table_ids = ["loot.beast_materials"]
```

## Implementation Plan

### Phase 0：确认迁移面

- 搜索并列出所有 `EntityDefinition.loot_table_id` 使用点。
- 区分三类使用：
  - addon API 字段
  - game content 配置
  - tests/docs 示例
- 确认没有 addon runtime 消费该字段。

验收：

- 迁移清单明确。
- 不修改无关系统。

### Phase 1：补齐死亡事件 killer payload

改动：

- `CombatEvents.entity_died(entity_id, entity_ref, killer_ref = null)`
- `HealthComponent.die(killer)` 调用时传入 `killer`
- 更新相关 tests，确认旧的死亡事件 payload 仍包含 entity 信息，并新增 killer 信息断言。

重点：

- `destroy_on_death` 仍必须在事件发出之后执行。
- killer 为空时事件仍可正常构造。

测试：

- `test_module_events.gd`
- `test_combat_status_feedback_integration.gd`
- 相关死亡事件 integration tests

### Phase 2：新增 loot death rule 类型

新增：

- `DeathLootRuleDefinition`
- `LootDropResult`
- `LootEvents`

改动：

- `docs/generated` 通过 `make docs-api` 生成，不手写。
- 新增 unit tests：
  - `DeathLootRuleDefinition.get_content_id()`
  - rule matching helper 覆盖 definition/faction/tags/excluded/disabled。

注意：

- 新 `.gd.uid` 由 Godot import/test 生成，不手写。

### Phase 3：实现 `DeathLootService`

新增：

- `addons/mkit/modules/loot/death_loot_service.gd`

行为：

- `_ready()` 订阅 `CombatEvents.ENTITY_DIED`。
- `process_death_event(event)` 可公开，便于测试。
- 查询 `ContentService.get_all_by_type("DeathLootRuleDefinition")`。
- 按 `priority` 降序处理。
- 每条匹配 rule 依次 roll `loot_table_ids`。
- 对每个 `LootRollResult` 发 `LootEvents.LOOT_DROPPED`。
- `stop_after_match` 为 true 时停止后续 rule。

不做：

- 不调用 `InventoryController`。
- 不 spawn pickup。
- 不播放 SFX。
- 不读 `EntityDefinition.loot_table_id`。

测试：

- 没有规则时无事件。
- faction/tag/definition 匹配正确。
- condition 失败时不 roll。
- 多 loot table 产生多个 drop event。
- `stop_after_match` 阻止低优先级规则。
- 缺 `LootService` 或 table 不存在时不崩溃。

### Phase 4：接入 ModuleBootstrap 与 demo

改动：

- `ModuleBootstrap._build_services()` 注册 `DeathLootService`。
- `Mkit` facade 可选新增 `death_loot()` 或 `loot_drops()` 访问器。
- `game/resources/village_rpg_content.tres` 新增 `DeathLootRuleDefinition` 子资源。
- 从 `EntityDefinition` demo 资源删除 `loot_table_id`。
- `game/village_rpg_demo.gd` 从“死亡后手动 roll 固定表”改为监听 `LootEvents.LOOT_DROPPED` 后交付到背包。

验收：

- demo 仍掉落 `Beast Claw` / `Field Blade`。
- demo 脚本不再硬编码“field beast 死亡时 roll 哪些 loot table”；它只处理 `loot_dropped` 的交付。

### Phase 5：删除旧字段并同步文档

改动：

- 删除 `EntityDefinition.loot_table_id`。
- 更新 cookbook 07 `EntityDefinition` 字段参考。
- 更新 cookbook 08 死亡掉落步骤，使用 `DeathLootRuleDefinition` + `LootEvents.LOOT_DROPPED`。
- 更新 API generated docs：`make docs-api`。
- 更新 `reviews/cookbook-all.md` 中对应决策项。

验收：

- `rg "loot_table_id" addons/mkit/modules/entity docs/cookbook/07_room.md` 不再出现旧字段。
- `rg "EntityDefinition.loot_table_id" docs reviews addons/mkit game test` 只允许出现在迁移说明或审查历史中；addon、game、test 和 cookbook 不再依赖旧字段。

### Phase 6：验证

运行：

```bash
make docs-check
make ut-modules
make int
make demo-test
make layering
```

重点检查：

- 没有新增 `addons/mkit/` -> `game/` 依赖。
- 没有具体敌人、掉落表、物品 id 写进 addon。
- `LootService`、`QuestService`、`ShopService` 仍是独立领域。
- `HealthComponent` 没有直接依赖 loot。

## Progress Tracker

| 阶段 | 状态 | 产出 | 备注 |
|------|------|------|------|
| P0 | Done | 迁移清单 | 旧字段只在迁移说明/审查历史中保留文本引用 |
| P1 | Done | 死亡事件 killer payload | `CombatEvents.entity_died(..., killer_ref)` 已补齐 killer identity payload |
| P2 | Done | `DeathLootRuleDefinition` / `LootDropResult` / `LootEvents` | `.gd.uid` 已由 Godot import 生成 |
| P3 | Done | `DeathLootService` + unit tests | 核心行为只 roll + emit，不做交付 |
| P4 | Done | ModuleBootstrap + demo migration | demo 只监听 `LootEvents.LOOT_DROPPED` 后交付到背包 |
| P5 | Done | 删除 `EntityDefinition.loot_table_id` + docs/API sync | 不保留兼容字段 |
| P6 | Done | docs/test/layering/demo gates | `make docs-check`、`make ut-modules`、`make int`、`make demo-test`、`make layering` 已通过 |

## Implementation Result

已按“更干净的方案”实现：

- `EntityDefinition.loot_table_id` 已删除，entity 模块不再承载死亡掉落配置。
- loot 模块新增 `DeathLootRuleDefinition`、`DeathLootService` 和 `LootDropResult`。
- `ModuleBootstrap` 默认注册 `DeathLootService`；无规则时无副作用。
- `CombatEvents.entity_died()` 补齐 killer payload，`HealthComponent.die(killer)` 会传入击杀者。
- demo content 用 `DeathLootRuleDefinition` 绑定 field beast 的掉落表。
- demo 只监听 `LootEvents.LOOT_DROPPED` 并决定把结果交付到玩家背包；具体交付仍归 game 侧。
- cookbook 07、cookbook 08、pipeline 和 cookbook audit 已同步新边界。

## Open Questions

1. `DeathLootService` 是否需要默认注册？
   - 建议默认注册。没有 `DeathLootRuleDefinition` 时它无副作用；有规则时按数据驱动发 `loot_dropped`。

2. 多规则匹配时是全部 roll 还是只 roll 第一个？
   - 建议全部 roll，按 `priority` 排序；需要短路时用 `stop_after_match`。

3. 掉落事件是否只在 `roll_result.item_instances` 非空时发？
   - 建议只对非空结果发 `LOOT_DROPPED`。如果调试空掉落，需要在 service 上保留可选 debug log 或把空 roll 写进 `recent_drops`，不要污染游戏事件流。

4. `LootTableDefinition` 是否只允许掉 `ItemInstance`？
   - 当前 `LootService.roll()` 产出 `ItemInstance`，先不扩展。奖励选择继续走 `RewardDefinition` / `RewardOption`，避免把“掉落”和“三选一奖励”混成一个 API。
