# Recipe 22：杀死敌人触发掉落  ·  难度 ★★☆  ·  预计 20 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

敌人死亡后会按数据表 roll 掉落。mkit 负责监听死亡事件、匹配 `DeathLootRuleDefinition`、调用 `LootService.roll_table()`，然后发出 `LootEvents.LOOT_DROPPED`。你的游戏代码决定这些掉落是直接进背包、生成地面拾取物，还是只弹 UI 提示。

关键边界：`EntityDefinition` 不配置掉落表。实体定义只描述“这是什么实体”；死亡奖励规则属于 loot 模块。

## 前置

- 需完成：[Recipe 03](03_health_and_stats.md)（实体有 `HealthComponent`，死亡时会发 `CombatEvents.ENTITY_DIED`）
- 推荐完成：[Recipe 06](06_ai_enemy.md)（敌人由 `EntitySpawner` 生成并带 `EntityIdentity.definition_id`）
- 若要直接进背包，需完成：[Recipe 16](16_items_and_inventory.md)（玩家有 `InventoryController`）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `ItemDefinition` 和 `LootTableDefinition` | `LootService.roll_table()` 按权重、数量和条件生成 `LootRollResult` |
| 创建 `DeathLootRuleDefinition`，写匹配条件和掉落表 id | `DeathLootService` 监听 `CombatEvents.ENTITY_DIED`，按规则匹配死亡实体 |
| 把资源加入 `ResourceDatabase.resources` | `ContentService` 注册并按 id / type 查找资源 |
| 监听 `LootEvents.LOOT_DROPPED`，把结果交付到背包或世界 | mkit 只发 typed drop event，不碰具体游戏交付方式 |

## 步骤

### 步骤 1：准备可掉落物品

先创建掉落物对应的 `ItemDefinition`，例如：

| 字段 | 值 |
|------|----|
| `item_id` | `"item.beast_claw"` |
| `display_name` | `"Beast Claw"` |
| `stackable` | `true` |
| `max_stack` | `99` |

把它保存为 `res://data/items/beast_claw.tres`，并加入 `ResourceDatabase.resources`。如果掉落装备，创建不可堆叠的 `ItemDefinition` 即可。

### 步骤 2：创建 LootTableDefinition

新建 Resource → `LootTableDefinition`，保存为 `res://data/loot/field_beast_drops.tres`：

| 字段 | 值 |
|------|----|
| `loot_table_id` | `"loot.field_beast"` |
| `rolls` | `2` |
| `allow_empty` | `true` |
| `empty_weight` | `1.0` |
| `entries` | Inspector 内嵌创建 `LootEntry` |

示例 entries：

| `content_id` | `weight` | `min_quantity` | `max_quantity` |
|--------------|----------|----------------|----------------|
| `"item.beast_claw"` | `3.0` | `1` | `2` |
| `"item.field_blade"` | `0.5` | `1` | `1` |

`rolls=2` 表示独立抽两次。`allow_empty=true` 且 `empty_weight=1.0` 时，“什么都不掉”也会作为一个权重项参与抽签。

### 步骤 3：创建 DeathLootRuleDefinition

新建 Resource → `DeathLootRuleDefinition`，保存为 `res://data/loot/field_beast_death_loot.tres`：

| 字段 | 值 |
|------|----|
| `rule_id` | `"death_loot.field_beast"` |
| `enabled` | `true` |
| `priority` | `0` |
| `entity_definition_ids` | `["entity.field_beast"]` |
| `loot_table_ids` | `["loot.field_beast"]` |
| `stop_after_match` | `false` |

匹配方式建议：

- 敌人由 `EntitySpawner` 生成：优先用 `entity_definition_ids`，最稳定。
- 手摆场景敌人：可用 `required_tags=["field_beast"]`，前提是 `EntityIdentity.tags` 里有这个 tag。
- 所有敌方单位共享基础掉落：可用 `factions=["enemy"]`。
- boss 专属规则不想叠加普通规则：把 boss 规则 `priority` 调高，并设 `stop_after_match=true`。

### 步骤 4：注册资源

把这些资源都加入同一个或多个 `ResourceDatabase.resources`：

```text
res://data/items/beast_claw.tres
res://data/items/field_blade.tres
res://data/loot/field_beast_drops.tres
res://data/loot/field_beast_death_loot.tres
```

`ModuleBootstrap` 默认注册 `DeathLootService` 和 `LootService`。没有 `DeathLootRuleDefinition` 时，死亡掉落服务无副作用。

### 步骤 5：监听掉落事件并交付

mkit 的死亡掉落链路到事件为止：

```text
HealthComponent.die(killer)
  -> CombatEvents.ENTITY_DIED
  -> DeathLootService 匹配 DeathLootRuleDefinition
  -> LootService.roll_table()
  -> LootEvents.LOOT_DROPPED
```

直接放进玩家背包：

```gdscript
func _ready() -> void:
    Mkit.events().subscribe(LootEvents.LOOT_DROPPED, _on_loot_dropped)


func _on_loot_dropped(event: DomainEvent) -> void:
    var drop := event.payload.get("drop") as LootDropResult
    if drop == null or drop.roll_result == null:
        return

    var player := get_tree().get_first_node_in_group("player")
    var inventory := EntityContract.get_controller(player, "InventoryController") as InventoryController
    if inventory == null:
        return

    for item in drop.roll_result.item_instances:
        inventory.add_item(item)
```

如果你的游戏要地面拾取物，把循环里的 `inventory.add_item(item)` 换成 spawn pickup scene。`drop.entity_ref` 是死亡实体节点引用；如果实体死亡后会 `queue_free()`，优先使用 `drop.entity_id` / `drop.entity_definition_id` 和死亡前记录的位置。

### 步骤 6：按条件扩展

`DeathLootRuleDefinition.conditions` 和 `LootEntry.conditions` 都会走 `ConditionEvaluator`。`DeathLootService` 会在 `GameplayContext.payload` 放入常用字段：

| key | 含义 |
|-----|------|
| `death_entity_id` | 死亡实体运行时 id |
| `death_definition_id` | 死亡实体定义 id |
| `killer_id` | 击杀者运行时 id，可能为空 |
| `rule_id` | 当前死亡掉落规则 id |
| `loot_table_id` | 当前正在 roll 的掉落表 id |

用法示例：

- 普通怪和精英怪共用一张表，但稀有 entry 加 `conditions`，只在精英 tag / 高难度时进入候选。
- boss 规则按 `entity_definition_ids` 精确匹配，普通怪规则按 `factions=["enemy"]` 兜底。
- 区域限定掉落可把区域 id 写进自定义 context payload，再用自定义 `Condition` 判断。

## 运行验证

1. 杀死目标敌人。
2. `EventService.recent_events` 中出现 `loot_dropped`。
3. `event.payload.drop` 是 `LootDropResult`。
4. `drop.roll_result.debug_rolls` 能看到每次 roll 的随机明细。
5. 你的交付代码执行后，玩家背包或地面 pickup 出现对应物品。

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 杀敌没有任何掉落事件 | `DeathLootRuleDefinition` 没入库，或规则没匹配 | 确认 `rule_id` 非空、资源在 `ResourceDatabase.resources`，并检查 `entity_definition_ids` / tags |
| 有死亡事件但没有 `loot_dropped` | roll 结果为空；服务只对非空结果发事件 | 临时把 `allow_empty=false` 或调高 entry 权重，用 `debug_rolls` 查概率 |
| 掉落表找不到 | `loot_table_ids` 拼错，或 `LootTableDefinition` 没入库 | 确认 `loot_table_id` 与规则里的字符串完全一致 |
| 进背包失败 | 玩家没有 `Controllers/InventoryController` | 按 [Recipe 16](16_items_and_inventory.md) 给玩家加背包控制器 |
| boss 掉了普通怪和 boss 两套奖励 | 多条规则都匹配，且没有短路 | boss 规则设高 `priority` 和 `stop_after_match=true` |

## 延伸阅读

- [DeathLootService ref](../generated/html/classes/DeathLootService.html) · [DeathLootRuleDefinition ref](../generated/html/classes/DeathLootRuleDefinition.html) · [LootDropResult ref](../generated/html/classes/LootDropResult.html)
- [LootTableDefinition ref](../generated/html/classes/LootTableDefinition.html) · [LootEntry ref](../generated/html/classes/LootEntry.html) · [LootRollResult ref](../generated/html/classes/LootRollResult.html)
- [Recipe 08](08_loot_and_rewards.md) — 房间清空后的 reward 选择
- [Recipe 16](16_items_and_inventory.md) — 物品定义、背包、装备和使用
- [pipeline.md — Loot Roll](../pipeline.md#14-loot-roll)
