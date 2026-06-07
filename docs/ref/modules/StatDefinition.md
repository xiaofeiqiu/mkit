# StatDefinition

**层：** Module  
**文件：** `addons/mkit/modules/combat/stats/stat_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

一个属性的元数据定义（`.tres`）：默认值、取值范围、是否百分比。可选——`StatsComponent` 用字符串 id + 数值即可工作，`StatDefinition` 提供面板展示与校验信息。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `stat_id` | `String` | `""` | 唯一 id（`get_content_id` 返回它）|
| `display_name` | `String` | `""` | 显示名 |
| `default_value` | `float` | `0.0` | 默认值 |
| `min_value` / `max_value` | `float` | `-INF` / `INF` | 取值范围 |
| `is_percent` | `bool` | `false` | 是否百分比展示 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在 .tres 配 stat_id="crit_chance"，display_name="暴击率"，is_percent=true
```

## 相关

- → [StatsComponent](StatsComponent.md) · [StatModifierDefinition](StatModifierDefinition.md)
