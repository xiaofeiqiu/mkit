# StatModifier

## 概念说明

StatModifier 是正在生效的运行时属性修改实例。它记录 modifier 来源、剩余时间、叠加层数、优先级和当前是否仍然有效。同一个 +20% attack 奖励可能永久存在，也可能只持续 10 秒；运行时实例让系统能正确过期、移除和调试。

## 设计目的

区分"静态修改规则"（StatModifierDefinition）和"运行时生效的具体实例"（StatModifier），使装备卸下、状态过期、临时 Buff 结束等移除操作能精确通过 modifier_id 和 source_id 定位到需要删除的实例。

## 文件

`res://addons/mkit/modules/stats/stat_modifier.gd`

## 字段说明

- **modifier_id**：稳定 ID 字段。例：StatModifier 通过 modifier_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **stat_id**：稳定 ID 字段。例：StatModifier 通过 stat_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **source_id**：行为来源 ID。例：伤害事件里 source_id=player_001，Analytics 和仇恨系统就知道是谁造成了伤害。
- **operation**：代码字段。运算类型。
- **value**：代码字段。数值。
- **priority**：代码字段。计算优先级。
- **stacking_rule**：代码字段。叠加规则。
- **remaining_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。

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
static func from_definition( definition: StatModifierDefinition, source: String, duration: float = -1.0 ) -> StatModifier
func to_save_data() -> Dictionary
static func from_save_data(data: Dictionary) -> StatModifier
```

## 函数使用场景

- **`from_definition(definition, source, duration)`**：工厂方法，从 StatModifierDefinition 创建运行时实例，并绑定来源 ID 和持续时间。`source` 通常是 ItemInstance.instance_id 或 StatusEffectInstance.instance_id，用于精确移除。`duration=-1` 表示永久生效（直到主动移除）。
- **`to_save_data()` / `from_save_data(data)`**：序列化和恢复 modifier 的 primitive payload，供 StatsComponent 保存永久 modifier、ItemInstance 保存 rolled_affixes。`operation` 和 `stacking_rule` 以 enum int 写入。

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
