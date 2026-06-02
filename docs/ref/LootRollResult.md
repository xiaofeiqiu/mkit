# LootRollResult

## 概念说明

LootRollResult 是一次掉落表掷骰后的生成结果。它保存生成出的物品实例、货币和调试信息。LootSystem 只负责生成结果；至于是直接进背包、掉在地上还是显示在宝箱 UI，由上层流程决定。

## 设计目的

把掉落结算结果与后续处理（放入背包、生成地面掉落物、展示 UI）解耦，使 LootSystem 只输出结构化数据，上层系统自行决定如何处置，保持职责单一。

## 文件

`res://addons/mkit/modules/loot/loot_roll_result.gd`

## 字段说明

- **item_instances**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **currency**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **debug_rolls**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name LootRollResult
extends RefCounted
var item_instances: Array[ItemInstance] = []
var currency: Dictionary = {}
var debug_rolls: Array[Dictionary] = []
```

## 函数使用场景

LootRollResult 是纯数据对象，无公开方法。由 LootSystem.roll() 创建并返回，调用方读取字段处理结果。

- **`item_instances`**：包含一组已创建的 ItemInstance，调用方可直接传给 InventoryController.add_item() 或生成地面掉落节点。
- **`currency`**：货币 ID 到数量的映射（如 `{"gold": 15}`），调用方传给 ProgressionSystem.add_currency()。
- **`debug_rolls`**：每次 roll 的详情（掷骰值、命中条目、数量），供 DebugOverlay 或测试脚本验证掉落行为。

## 使用示例

```gdscript
var loot_system := LootSystem.new()
var ctx := GameplayContext.new()
ctx.source = enemy
ctx.target = player

var result := loot_system.roll_table("loot.goblin_common", ctx)

# 把物品放入玩家背包
var inventory := player.get_node("Controllers/InventoryController") as InventoryController
for item in result.item_instances:
    inventory.add_item(item)

# 发放货币
for currency_id in result.currency.keys():
    var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
    progression.add_currency(currency_id, result.currency[currency_id])
```
