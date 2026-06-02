# StatDefinition

## 概念说明

StatDefinition 是一个属性类型的静态定义，例如 `max_hp`、`attack_power`、`move_speed`、`crit_chance`。它定义属性 ID、默认值、取值范围和编辑器/显示层需要的元数据。装备、Buff、奖励和敌人缩放都会修改属性；先定义属性类型，StatsComponent 才能用同一套规则计算最终值。

## 设计目的

提供稳定的属性 ID 和约束范围定义，使所有修改属性的系统（装备、状态效果、奖励、升级）都引用同一套属性 ID，避免拼写不一致或范围计算混乱。

## 文件

`res://addons/mkit/modules/stats/stat_definition.gd`

## 接口

```gdscript
class_name StatDefinition
extends Resource

@export var stat_id: String = ""
@export var display_name: String = ""
@export var default_value: float = 0.0
@export var min_value: float = -INF
@export var max_value: float = INF
@export var is_percent: bool = false
```

## 函数使用场景

StatDefinition 是纯数据 Resource，无公开方法。字段由编辑器配置后注册到 ContentRegistry，供 StatsComponent 和 UI 读取。

- **`stat_id`**：全局唯一属性 ID，StatsComponent、StatModifierDefinition 和 ApplyStatModifierEffect 均通过此 ID 引用属性。
- **`default_value`**：未被任何 modifier 影响时的基础值，StatsComponent 初始化时读取。
- **`min_value` / `max_value`**：计算最终属性时的 Clamp 边界，防止属性变为非法值（如负防御、超高暴击率）。
- **`is_percent`**：标记属性是否以百分比表达，供 UI 选择显示格式（如 "5%" vs "5"）。

## 使用示例

```gdscript
var attack := StatDefinition.new()
attack.stat_id = "attack_power"
attack.display_name = "Attack Power"
attack.default_value = 10.0
attack.min_value = 0.0
attack.max_value = 9999.0

var crit := StatDefinition.new()
crit.stat_id = "crit_chance"
crit.display_name = "Crit Chance"
crit.default_value = 0.05
crit.min_value = 0.0
crit.max_value = 1.0
crit.is_percent = true
```
