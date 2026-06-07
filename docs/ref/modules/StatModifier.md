# StatModifier

**层：** Module  
**文件：** `addons/mkit/modules/combat/stats/stat_modifier.gd`  
**继承：** `extends RefCounted`

## 职责

属性修饰器的**运行时实例**，由 `StatModifierDefinition` 生成并加到 `StatsComponent`。带 `source_id`（便于按来源批量移除，如卸装备）和 `remaining_duration`（限时 buff）。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `modifier_id` / `stat_id` / `source_id` | `String` | `""` | 标识 / 目标属性 / 来源 |
| `operation` | `Operation` | — | 运算方式 |
| `value` | `float` | `0.0` | 数值 |
| `priority` | `int` | `0` | 计算顺序 |
| `stacking_rule` | `StackingRule` | — | 叠加规则 |
| `remaining_duration` | `float` | `-1.0` | 剩余时间（`-1` 永久）|
| `tags` | `Array[String]` | `[]` | 标签 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static from_definition(definition, source, duration := -1.0)` | `StatModifier` | 由定义生成 |
| `to_save_data()` / `static from_save_data(data)` | — / `StatModifier` | 序列化 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var mod := StatModifier.from_definition(mod_def, "buff.rage", 8.0)  # 8 秒后自动移除
(entity.get_node("Components/StatsComponent") as StatsComponent).add_modifier(mod)
```

## 相关

- → [StatModifierDefinition](StatModifierDefinition.md) · [StatsComponent](StatsComponent.md)
