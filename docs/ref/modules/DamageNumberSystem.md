# DamageNumberSystem

**层：** Module  
**文件：** `addons/mkit/modules/ui/damage_number_system.gd`  
**继承：** `extends Node`

## 职责

伤害数字生成器。实例化 `damage_number_scene_path`，定位到目标坐标偏移处，并调用实例的 `setup(amount, critical)`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `damage_number_scene_path` | `String`（@export）| `""` | 数字场景路径 |
| `default_offset` | `Vector2`（@export）| `Vector2(0, -24)` | 显示偏移 |
| `use_pool` | `bool`（@export）| `false` | 是否通过 `PoolService` 获取实例 |
| `auto_release_seconds` | `float`（@export）| `0.0` | 使用池时自动归还延迟 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `show_number(position: Vector2, amount: float, critical: bool = false) -> Node` | `Node` | 成功返回生成节点，路径无效返回 `null` |

## 使用模式

### 最小示例（Level 1）

```gdscript
$DamageNumberSystem.show_number(Vector2(100, 80), 12.0, false)
```

### 典型场景（Level 2）

```gdscript
func on_damage(result: DamageResult) -> void:
    var numbers := $DamageNumberSystem as DamageNumberSystem
    if result == null or result.target == null:
        return
    numbers.show_number(result.target.global_position, result.final_amount, result.was_critical)
```

## 相关

- → [FeedbackSystem](FeedbackSystem.md) · [DamageResult](DamageResult.md) · [PoolService](../kernel/PoolService.md)

