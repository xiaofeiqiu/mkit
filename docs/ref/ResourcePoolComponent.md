# ResourcePoolComponent

## 概念说明

ResourcePoolComponent 是实体的可消耗资源池，例如 mana、stamina、energy、rage。它保存当前资源值，从 StatsComponent 读取最大值，并执行消耗、恢复和变化通知。AbilityController 的 cost_type/cost_amount 依赖它；若没有统一资源池，技能消耗会被写死在具体玩家脚本里。

## 设计目的

把各类可消耗资源（mana、stamina 等）的当前值统一管理，最大值由 StatsComponent 中以 `"max_{resource_id}"` 命名的属性决定，实现资源消耗、恢复和存档的一致性，并通过信号通知 UI 更新。

## 文件

`res://addons/mkit/modules/health/resource_pool_component.gd`

## 接口

```gdscript
class_name ResourcePoolComponent
extends Node

signal resource_changed(resource_id: String, current: float, max_value: float)
signal resource_spent(resource_id: String, amount: float)
signal resource_restored(resource_id: String, amount: float)

@export var starting_values: Dictionary = {} # resource_id -> current value

var current_values: Dictionary = {}
var stats: StatsComponent = null

func _ready() -> void: ...
func get_current(resource_id: String) -> float: ...
func get_max_resource(resource_id: String) -> float: ...
func has_resource(resource_id: String, amount: float) -> bool: ...
func spend(resource_id: String, amount: float) -> bool: ...
func restore(resource_id: String, amount: float) -> void: ...
func set_current(resource_id: String, value: float) -> void: ...
func to_save_data() -> Dictionary: ...
func from_save_data(data: Dictionary) -> void: ...
```

## 函数使用场景

- **`get_current(resource_id)`**：读取当前资源值，供 UI 显示 mana/stamina 条或 HUD 数字。
- **`get_max_resource(resource_id)`**：从 StatsComponent 读取 `"max_{resource_id}"` 属性的最终值，使最大资源受 modifier 影响。
- **`has_resource(resource_id, amount)`**：消耗前检查，AbilityController 判断是否有足够 mana 或 stamina 施放技能。
- **`spend(resource_id, amount)`**：消耗指定量资源，若不足则返回 false 且不消耗。释放技能、使用冲刺等操作通过此方法扣除资源。
- **`restore(resource_id, amount)`**：恢复资源，常见于药水恢复 mana、拾取能量球恢复 stamina。
- **`set_current(resource_id, value)`**：直接设置当前值（会 clamp 到 [0, max]），用于读档恢复或调试工具。
- **`to_save_data()` / `from_save_data(data)`**：序列化和反序列化当前资源值，供 SaveManager 保存和恢复玩家资源状态。

## 使用示例

```gdscript
var resources := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent

# 检查并消耗 mana
if resources.spend("mana", 15.0):
    print("Cast fireball")
else:
    print("Not enough mana")

# 恢复 stamina
resources.restore("stamina", 25.0)

# 存档 / 读档
var save_data := resources.to_save_data()
resources.from_save_data(save_data)
```
