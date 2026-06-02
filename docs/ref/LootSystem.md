# LootSystem

## 概念说明

LootSystem 是掉落表生成服务。它按权重、条件、数量范围和随机种子生成 LootRollResult。敌人死亡、宝箱、Boss、商店库存都需要一致且可测试的掉落逻辑。

## 设计目的

把掉落逻辑集中到一个无状态的服务类，使所有掉落来源（敌人死亡、宝箱开启、奖励事件）都走同一套权重选择和条件过滤管线，并利用 RandomService 保证固定 seed 下结果可复现。

## 文件

`res://addons/mkit/modules/loot/loot_system.gd`

## 接口

```gdscript
class_name LootSystem
extends RefCounted

func roll_table(table_id: String, context: GameplayContext) -> LootRollResult: ...
func roll(table: LootTableDefinition, context: GameplayContext) -> LootRollResult: ...
func _get_valid_entries(table: LootTableDefinition, context: GameplayContext) -> Array[LootEntry]: ...
func _roll_quantity(entry: LootEntry) -> int: ...
```

## 函数使用场景

- **`roll_table(table_id, context)`**：按 ID 从 ContentRegistry 查找 LootTableDefinition，然后调用 `roll()`。敌人死亡或宝箱开启时直接传入 loot_table_id 调用此方法。
- **`roll(table, context)`**：核心逻辑：按 `table.rolls` 次数循环，每次用 RandomService 在所有有效条目（包含 empty_weight）中按权重抽取，生成 ItemInstance 并记录 debug_rolls。
- **`_get_valid_entries(table, context)`**：内部方法，过滤掉条件不满足的 LootEntry，返回本次 roll 的有效候选列表。
- **`_roll_quantity(entry)`**：内部方法，用 RandomService.randi_range 在 entry.min_quantity 到 max_quantity 之间随机数量。

## 使用示例

```gdscript
var loot_system := LootSystem.new()
var ctx := GameplayContext.new()
ctx.source = enemy
ctx.target = player
ctx.payload["room_id"] = "room_001"

var result := loot_system.roll_table("loot.goblin_common", ctx)

var inventory := player.get_node("Controllers/InventoryController") as InventoryController
for item in result.item_instances:
    inventory.add_item(item)
```
