# LootTableDefinition

## 概念说明

LootTableDefinition 是一张完整掉落表的静态定义。它组合多个 LootEntry，设置 roll 次数、是否允许空掉落、空掉落权重和整体规则。敌人、宝箱、Boss、商店库存都可以通过掉落表生成奖励，而不是在死亡脚本里写随机逻辑。

## 设计目的

把掉落行为的所有参数（roll 次数、空掉落概率、候选条目）集中到一个 Resource，使任何来源（敌人、宝箱、事件）只需引用 `loot_table_id` 就能得到一致且可复现的掉落结果。

## 文件

`res://addons/mkit/modules/loot/loot_table_definition.gd`

## 字段说明

- **loot_table_id**：稳定 ID 字段。例：LootTableDefinition 通过 loot_table_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **rolls**：掉落表掷骰次数。例：Boss 宝箱 rolls=3，普通敌人 rolls=1。
- **entries**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **allow_empty**：是否允许空掉落。例：普通小怪可以空掉落，Boss 宝箱不应该空。
- **empty_weight**：空掉落权重。例：empty_weight 越高，普通怪越可能不掉东西。

## 接口

```gdscript
class_name LootTableDefinition
extends Resource
@export var loot_table_id: String = ""
@export var rolls: int = 1
@export var entries: Array[LootEntry] = []
@export var allow_empty: bool = true
@export var empty_weight: float = 0.0
func get_resource_id() -> String
```

## 函数使用场景

LootTableDefinition 是纯数据 Resource，无公开方法。字段由 Inspector 配置后注册到 ContentRegistry，LootSystem 按 ID 查找并使用。

- **`rolls`**：LootSystem 对掉落表进行多次独立掷骰；Boss 宝箱可配置 rolls=3，保证掉出多个物品。
- **`allow_empty` / `empty_weight`**：`allow_empty=true` 时 LootSystem 将 empty_weight 加入权重总量，使某些 roll 结果为空。普通小怪可以不掉东西，Boss 可以设 `allow_empty=false`。

## 使用示例

```gdscript
var table := LootTableDefinition.new()
table.loot_table_id = "loot.goblin_common"
table.rolls = 1
table.allow_empty = true
table.empty_weight = 5.0
table.entries = [potion_entry, gold_entry, sword_entry]
```
