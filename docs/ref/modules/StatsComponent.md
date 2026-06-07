# StatsComponent

**层：** Module  
**文件：** `addons/mkit/modules/combat/stats/stats_component.gd`  
**继承：** `extends SaveableComponent`

## 职责

实体属性中枢，挂在 `Components/StatsComponent`。维护基础值 + 修饰器，按运算顺序惰性计算最终值（带脏标记缓存）。`CombatService`、`HealthComponent`、`ResourcePoolComponent`、`AbilityController` 都读它。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `base_stats` | `Dictionary`（@export）| 见源码 | 基础属性（`max_hp`/`attack_power`/`defense`/`crit_chance`…）|
| `modifiers_by_stat` | `Dictionary` | `{}` | 各属性的修饰器列表 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_stat_value(stat_id, default := 0.0) -> float` | `float` | 计算后的最终值 |
| `set_base_stat(stat_id, value) -> void` | — | 改基础值并发 `stat_changed` |
| `add_modifier(modifier: StatModifier) -> void` | — | 加修饰器（按 `stacking_rule`）|
| `remove_modifier(modifier_id, source_id := "") -> void` | — | 按 id 移除 |
| `remove_modifiers_from_source(source_id) -> void` | — | 按来源批量移除（卸装备/状态结束）|
| `tick_modifiers(delta) -> void` | — | 推进限时修饰器并清理到期项 |
| `mark_save_baseline() -> void` | — | 记录基础值基线（存档只存相对覆盖）|

## 信号

`stat_changed(stat_id, old_value, new_value)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var stats := player.get_node("Components/StatsComponent") as StatsComponent
print(stats.get_stat_value("attack_power"))
stats.set_base_stat("max_hp", 150.0)
```

### 典型场景（Level 2）

```gdscript
# 临时 buff：限时加攻击力，结束自动回落
func apply_rage(entity: Node, seconds: float) -> void:
    var stats := entity.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats == null:
        return
    var mod_def := StatModifierDefinition.new()
    mod_def.modifier_id = "rage"
    mod_def.stat_id = "attack_power"
    mod_def.operation = StatModifierDefinition.Operation.PERCENT_ADD
    mod_def.value = 0.5   # +50%
    var mod := StatModifier.from_definition(mod_def, "rage", seconds)
    stats.add_modifier(mod)
    stats.stat_changed.connect(func(id: String, _o: float, n: float):
        if id == "attack_power":
            print("攻击力 → %.0f" % n)
    )
# 需要每帧推进限时修饰器：在某处 stats.tick_modifiers(delta)
```

> 存档：`StatsComponent` 是 `SaveableComponent`，存的是相对 `mark_save_baseline()` 的覆盖与持久修饰器，需由 `Saveable` 代理收集。

## 相关

- → [StatDefinition](StatDefinition.md) · [StatModifier](StatModifier.md) · [StatModifierDefinition](StatModifierDefinition.md) · [ApplyStatModifierEffect](ApplyStatModifierEffect.md)
- → [cookbook/03_health_and_stats.md](../../cookbook/03_health_and_stats.md)
