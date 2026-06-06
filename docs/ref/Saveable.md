# Saveable

## 概念说明

Saveable 是节点可存档的契约基类。它提供 save_id、to_save_data 和 from_save_data 接口。SaveManager 不应该知道每个模块内部字段，由对象自己贡献可持久化数据。

Saveable 用于**顶层全局存档单元**——在 `game_bootstrap.gd` 中构建、按 save_id 被 SaveManager 直接遍历收集的独立系统，例如 `ProgressionSystem`（`"progression"`）、`QuestSystem`（`"quest"`）、`AudioManager`（`"audio"`）。它与 [SaveableComponent](SaveableComponent.md) 是两条**有意分离**的存档契约（都 `extends Node`，互不继承）：实体内部挂在 `Components/` / `Controllers/` 下的 per-entity 子状态用 SaveableComponent（按 `get_save_key()` 聚合，避免同名组件跨实体覆盖），不要因为类名里带 "Component" 就归错类——`ProgressionSystem` 是全局系统，所以是 Saveable 而非 SaveableComponent。

## 设计目的

通过统一的接口约定，使 SaveManager 可以无差别地遍历场景树中所有 Saveable 节点，收集或分发存档数据，而不需要了解每个模块的具体字段结构。

## 文件

`res://addons/mkit/kernel/save/saveable.gd`

## 字段说明

- **save_id**：稳定 ID 字段。例：Saveable 通过 save_id 引用某个定义或运行时对象，避免直接保存节点路径。

## 接口

```gdscript
class_name Saveable
extends Node
@export var save_id: String = ""
func get_save_id() -> String
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`get_save_id()`**：SaveManager 用此方法获取每个 Saveable 的唯一键，写入存档 payload 字典或从中读取对应数据。未在 Inspector 中设置 save_id 时，使用 owner.name 作为默认键。
- **`to_save_data()`**：子类重写，返回需要持久化的字段。例如 PlayerSaveable 返回 position、current_hp 和 inventory 数据。SaveManager.save_game() 调用。
- **`from_save_data(data)`**：子类重写，从存档 Dictionary 恢复状态。例如恢复玩家位置、HP 和背包内容。SaveManager.load_game() 调用。

## 使用示例

### 自定义 PlayerSaveable

```gdscript
class_name PlayerSaveable
extends Saveable

func to_save_data() -> Dictionary:
    var health := owner.get_node("Components/HealthComponent") as HealthComponent
    var inventory := owner.get_node("Controllers/InventoryController") as InventoryController
    return {
        "position": owner.global_position,
        "current_hp": health.current_hp,
        "inventory": inventory.to_save_data()
    }

func from_save_data(data: Dictionary) -> void:
    owner.global_position = data.get("position", Vector2.ZERO)
    var health := owner.get_node("Components/HealthComponent") as HealthComponent
    health.current_hp = float(data.get("current_hp", health.get_max_hp()))

    var inventory := owner.get_node("Controllers/InventoryController") as InventoryController
    inventory.from_save_data(data.get("inventory", {}))
```
