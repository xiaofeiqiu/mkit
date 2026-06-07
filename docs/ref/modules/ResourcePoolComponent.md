# ResourcePoolComponent

**层：** Module  
**文件：** `addons/mkit/modules/combat/health/resource_pool_component.gd`  
**继承：** `extends SaveableComponent`

## 职责

管理魔法/耐力等可消耗资源池，挂在 `Components/ResourcePoolComponent`。技能消耗（`AbilityController` 的 `cost_type`/`cost_amount`）走它。每个池的上限取自 `StatsComponent` 的 `max_<resource_id>`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `starting_values` | `Dictionary`（@export）| `{}` | `resource_id → 初始值` |
| `current_values` | `Dictionary` | `{}` | 当前各池值 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_current(resource_id) -> float` | `float` | 当前值 |
| `get_max_resource(resource_id) -> float` | `float` | 上限（`StatsComponent.max_<id>`）|
| `has_resource(resource_id, amount) -> bool` | `bool` | 是否够 |
| `spend(resource_id, amount) -> bool` | `bool` | 消耗，不够返回 false |
| `restore(resource_id, amount) -> void` | — | 回复 |

## 信号

`resource_changed(id, current, max)` · `resource_spent(id, amount)` · `resource_restored(id, amount)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var pool := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent
# Inspector: starting_values = {"mana": 100.0}；StatsComponent.max_mana 决定上限
if pool.has_resource("mana", 20.0):
    pool.spend("mana", 20.0)
```

## 相关

- → [ref/modules/AbilityController.md](AbilityController.md)（消耗它）· [ref/modules/StatsComponent.md](StatsComponent.md)（提供上限）
- → [cookbook/05_ability.md](../../cookbook/05_ability.md)
