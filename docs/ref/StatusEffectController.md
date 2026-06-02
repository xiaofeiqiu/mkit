# StatusEffectController

## 概念说明

StatusEffectController 是实体身上状态效果的管理器。它负责应用、刷新、叠加、tick、过期和移除状态。持续伤害、Buff、Debuff 如果散落在各个技能脚本里，会很快失控；统一控制器保证所有状态遵循一致的叠加规则和生命周期。

## 设计目的

集中管理实体的所有活跃状态，对外提供简洁的 apply/remove/has 接口，内部处理叠加规则（StackRule）、周期效果（effects_on_tick）、属性 modifier 的施加与撤销，使技能、陷阱、装备只需请求 apply_status，而无需自己管理 Timer 或状态列表。

## 文件

`res://addons/mkit/modules/status_effects/status_effect_controller.gd`

## 字段说明

- **active_statuses**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **content**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name StatusEffectController
extends Node
signal status_applied(status_id: String, stacks: int)
signal status_removed(status_id: String)
signal status_ticked(status_id: String)
var active_statuses: Dictionary = {}
var content: ContentRegistry = null
func apply_status( status_id: String, source: Node, stacks: int = 1, duration_override: float = -1.0 ) -> bool
func remove_status(status_id: String) -> void
func has_status(status_id: String) -> bool
func get_definition(status_id: String) -> StatusEffectDefinition
```

## 函数使用场景

- **`apply_status(status_id, source, stacks, duration_override)`**：施加状态的主接口。若该状态已存在则按 StackRule 刷新/叠加；若不存在则创建新 StatusEffectInstance，施加 stat_modifiers 到 StatsComponent，并执行 effects_on_apply。ApplyStatusEffect 和 HealthComponent 的 on-hit 状态路径都调用此方法。
- **`remove_status(status_id)`**：移除活跃状态，执行 effects_on_remove，并从 StatsComponent 撤销该实例的所有 stat_modifiers。驱散效果或死亡清理时调用。
- **`has_status(status_id)`**：检查实体是否当前具有指定状态，供条件、AI 或 UI 查询（如"已燃烧则不再叠加"）。
- **`get_definition(status_id)`**：从 ContentRegistry 读取 StatusEffectDefinition，内部 tick 和 apply 流程调用。

## 使用示例

### 施加状态

```gdscript
var status_controller := enemy.get_node("Controllers/StatusEffectController") as StatusEffectController
status_controller.apply_status("status.burn", player, 1)
```

### 判断是否已有状态

```gdscript
if status_controller.has_status("status.burn"):
    print("Enemy is burning")
```

### 移除状态

```gdscript
status_controller.remove_status("status.burn")
```
