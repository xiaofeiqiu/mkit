# DamageNumberSystem

## 概念说明

DamageNumberSystem 是伤害数字显示系统。它生成伤害数字 UI/Node2D，设置数值、暴击样式和位置。DamageResult 已经记录最终伤害；显示层应该读取这个结果，而不是自己重新计算伤害。

## 设计目的

把伤害数字的生成逻辑与具体场景动画解耦，使 FeedbackSystem 只需传入位置、数值和是否暴击，具体的字体、颜色、飘出动画由 DamageNumber 场景自行处理。

## 文件

`res://addons/mkit/modules/ui/damage_number_system.gd`

## 字段说明

- **damage_number_scene_path**：伤害数字场景路径。例：指向 FloatingDamageNumber.tscn。
- **default_offset**：显示偏移。例：数字从敌人头顶上方弹出。

## 接口

```gdscript
class_name DamageNumberSystem
extends Node
@export var damage_number_scene_path: String = ""
@export var default_offset: Vector2 = Vector2(0, -24)
func show_number(position: Vector2, amount: float, critical: bool = false) -> Node
```

## 函数使用场景

- **`show_number(position, amount, critical)`**：加载 `damage_number_scene_path` 的 PackedScene，实例化后设置 global_position（含 default_offset），若节点有 `setup(amount, critical)` 方法则调用传入数值和暴击标志。FeedbackSystem 在收到 DamageResult 后调用此方法。damage_number_scene_path 为空或场景不存在时返回 null，不影响战斗结算。

## 使用示例

```gdscript
# 显示普通伤害数字
$DamageNumberSystem.show_number(enemy.global_position, 27.0, false)

# 显示暴击伤害数字（通常显示更大、颜色不同）
$DamageNumberSystem.show_number(enemy.global_position, 54.0, true)
```
