# LootEntry

## 概念说明

LootEntry 是掉落表中的一个候选掉落项。它定义可能掉落什么内容、权重是多少、最小/最大数量和出现条件。一个 goblin_common 掉落表可能包含药水、金币、普通剑和空掉落，每个候选都需要独立权重。

## 设计目的

把掉落表中每个候选项的配置（内容 ID、权重、数量范围、条件）封装为独立 Resource，使 LootSystem 能按权重和条件筛选有效候选，生成多样化且可配置的掉落结果。

## 文件

`res://addons/mkit/modules/loot/loot_entry.gd`

## 字段说明

- **content_id**：稳定 ID 字段。例：LootEntry 通过 content_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **weight**：权重。例：普通药水 weight=10，稀有武器 weight=1。
- **min_quantity**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **max_quantity**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。

## 接口

```gdscript
class_name LootEntry
extends Resource
@export var content_id: String = ""
@export var weight: float = 1.0
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export var conditions: Array[Condition] = []
```

## 函数使用场景

LootEntry 是纯数据 Resource，无公开方法。字段由 Inspector 配置后挂入 LootTableDefinition.entries，由 LootSystem 读取。

- **`content_id`**：被掉落的物品或货币的定义 ID，LootSystem 通过 ContentRegistry 查找并创建 ItemInstance。
- **`weight`**：相对权重，LootSystem 按权重比例选取候选条目；权重越高出现概率越大。
- **`min_quantity` / `max_quantity`**：LootSystem 用 RandomService.randi_range 在此范围内掷数量。
- **`conditions`**：仅当所有条件通过时，该条目才进入有效候选池。例如只有在 Boss 房间才出现稀有掉落。

## 使用示例

```gdscript
var potion_entry := LootEntry.new()
potion_entry.content_id = "item.potion_small"
potion_entry.weight = 10.0
potion_entry.min_quantity = 1
potion_entry.max_quantity = 3

var sword_entry := LootEntry.new()
sword_entry.content_id = "item.sword_iron"
sword_entry.weight = 1.0
sword_entry.min_quantity = 1
sword_entry.max_quantity = 1
```
