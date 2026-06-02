# StatModifier

## 概念说明

StatModifier 是正在生效的运行时属性修改实例。它记录 modifier 来源、剩余时间、叠加层数、优先级和当前是否仍然有效。同一个 +20% attack 奖励可能永久存在，也可能只持续 10 秒；运行时实例让系统能正确过期、移除和调试。

## 设计目的

区分"静态修改规则"（StatModifierDefinition）和"运行时生效的具体实例"（StatModifier），使装备卸下、状态过期、临时 Buff 结束等移除操作能精确通过 modifier_id 和 source_id 定位到需要删除的实例。

## 文件

`res://addons/mkit/modules/stats/stat_modifier.gd`

## 接口

```gdscript
class_name StatModifier
extends RefCounted

var modifier_id: String = ""
var stat_id: String = ""
var source_id: String = ""
var operation: StatModifierDefinition.Operation
var value: float = 0.0
var priority: int = 0
var stacking_rule: StatModifierDefinition.StackingRule
var remaining_duration: float = -1.0
var tags: Array[String] = []

static func from_definition(definition: StatModifierDefinition, source: String, duration: float = -1.0) -> StatModifier:
    var m := StatModifier.new()
    m.modifier_id = definition.modifier_id
    m.stat_id = definition.stat_id
    m.source_id = source
    m.operation = definition.operation
    m.value = definition.value
    m.priority = definition.priority
    m.stacking_rule = definition.stacking_rule
    m.remaining_duration = duration
    m.tags = definition.tags.duplicate()
    return m
```

## 函数使用场景

- **`from_definition(definition, source, duration)`**：工厂方法，从 StatModifierDefinition 创建运行时实例，并绑定来源 ID 和持续时间。`source` 通常是 ItemInstance.instance_id 或 StatusEffectInstance.instance_id，用于精确移除。`duration=-1` 表示永久生效（直到主动移除）。

## 使用示例

```gdscript
# 装备铁剑时创建 modifier
var modifier := StatModifier.from_definition(
    sword_attack_definition,
    "item_instance_001"
)
var stats := player.get_node("Components/StatsComponent") as StatsComponent
stats.add_modifier(modifier)

# 卸下铁剑时移除
stats.remove_modifiers_from_source("item_instance_001")

# 临时 5 秒攻击 buff
var buff := StatModifier.from_definition(berserk_def, "status.berserk", 5.0)
stats.add_modifier(buff)
```
