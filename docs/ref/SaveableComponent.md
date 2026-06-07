# SaveableComponent

## 概念说明

SaveableComponent 是实体内部组件可被聚合存档的契约基类。它和 Saveable 都提供 `to_save_data()` / `from_save_data()`，但语义不同：Saveable 是顶层全局节点由 SaveManager 直接收集，SaveableComponent 是挂在实体 `Components/` 或 `Controllers/` 下的子状态，由宿主 Saveable（如实体根节点）按组件 key 显式聚合。

**注意：** addon 当前不提供通用实体聚合器。宿主实体的 Saveable 负责遍历自身 `SaveableComponent` 子节点并拼装 `components` 字典；仅实现 SaveableComponent 接口不等于该组件会被 SaveManager 自动保存。

## 设计目的

把 per-entity runtime state 从顶层 Saveable 命名空间中拆出来，避免同名组件相互覆盖，并让 Health、Stats、Ability、Inventory、Equipment 等模块以统一接口贡献实体快照。Kernel 只定义契约，不理解具体组件字段，保持依赖方向为 Module Layer → Kernel Layer。

## 文件

`res://addons/mkit/kernel/save/saveable_component.gd`

## 接口

```gdscript
class_name SaveableComponent
extends Node
func get_save_key() -> String
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`get_save_key()`**：返回组件在实体快照中的 key，默认使用节点 `name`。宿主 Saveable 调用此方法把 `HealthComponent`、`InventoryController` 等组件数据写进同一个 `components` Dictionary，确保同名组件挂在不同实体上时不会相互覆盖。
- **`to_save_data()`**：子类重写，返回 portable primitive Dictionary，只保存无法从 Definition 或 ContentRegistry 重算的运行时状态。
- **`from_save_data(data)`**：子类重写，从组件 payload 恢复运行时状态。调用方应按 Stats → Status → Health 等需要的顺序恢复。

## 使用示例

```gdscript
var component := player.get_node("Components/HealthComponent") as SaveableComponent
var key := component.get_save_key()
var data := component.to_save_data()

component.from_save_data(data)
print(key)
```
