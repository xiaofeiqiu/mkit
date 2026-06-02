# StatModifierDefinition

## 概念说明

StatModifierDefinition 是描述"如何改变属性"的静态规则，例如 `attack_power +5`、`move_speed +20%`、`max_hp` 限制到 1 以上。它描述修改哪个属性、用哪种操作（FlatAdd/PercentAdd/PercentMultiply/Override 等）、数值是多少、如何叠加。铁剑、燃烧 Debuff、房间祝福、Run 奖励都可能改属性；统一 modifier 定义可以避免每个系统自己修改最终数值。

## 设计目的

把"怎么改属性"抽象为可复用的 Resource，让装备、状态效果、奖励和升级都遵循同一套计算规则和叠加语义，保证属性最终值计算可预期、可调试。

## 文件

`res://addons/mkit/modules/stats/stat_modifier_definition.gd`

## 接口

```gdscript
class_name StatModifierDefinition
extends Resource

enum Operation {
    FLAT_ADD,
    PERCENT_ADD,
    PERCENT_MULTIPLY,
    OVERRIDE,
    CLAMP_MIN,
    CLAMP_MAX
}

enum StackingRule {
    STACK,
    REPLACE_SAME_SOURCE,
    HIGHEST_ONLY,
    LOWEST_ONLY,
    UNIQUE
}

@export var modifier_id: String = ""
@export var stat_id: String = ""
@export var operation: Operation = Operation.FLAT_ADD
@export var value: float = 0.0
@export var priority: int = 0
@export var stacking_rule: StackingRule = StackingRule.STACK
@export var tags: Array[String] = []
```

## 函数使用场景

StatModifierDefinition 是纯数据 Resource，无公开方法。由 `StatModifier.from_definition()` 实例化为运行时 StatModifier，再通过 StatsComponent.add_modifier() 生效。

- **`operation`**：决定计算方式：`FLAT_ADD` 直接相加，`PERCENT_ADD` 累加百分比后乘以基础值，`PERCENT_MULTIPLY` 连乘系数，`OVERRIDE` 强制覆盖，`CLAMP_MIN/MAX` 限定范围。
- **`stacking_rule`**：决定同 ID 或同来源的 modifier 如何处理：`STACK` 全部叠加，`UNIQUE` 同 ID 只保留一个，`REPLACE_SAME_SOURCE` 同来源的替换。
- **`priority`**：决定 modifier 的计算顺序，数值越小优先级越高（越先计算）。

## 使用示例

```gdscript
var sword_attack := StatModifierDefinition.new()
sword_attack.modifier_id = "mod.sword_iron.attack"
sword_attack.stat_id = "attack_power"
sword_attack.operation = StatModifierDefinition.Operation.FLAT_ADD
sword_attack.value = 5.0
sword_attack.stacking_rule = StatModifierDefinition.StackingRule.UNIQUE

var berserk_buff := StatModifierDefinition.new()
berserk_buff.modifier_id = "mod.buff.attack_20_percent"
berserk_buff.stat_id = "attack_power"
berserk_buff.operation = StatModifierDefinition.Operation.PERCENT_ADD
berserk_buff.value = 0.20
berserk_buff.stacking_rule = StatModifierDefinition.StackingRule.STACK
```
