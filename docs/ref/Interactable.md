# Interactable

## 概念说明

Interactable 是世界中可被互动的对象基类。它提供显示文本、互动条件和执行逻辑的统一接口。宝箱、门、NPC、祭坛、开关都可以共享同一个互动协议。

## 设计目的

定义所有可互动对象的统一接口，使 InteractionComponent 可以用一套代码处理所有类型的互动对象，UI 只需读取 `display_text`，互动执行只需调用 `interact()`，不需要了解具体类型。

## 文件

`res://addons/mkit/modules/interaction/interactable.gd`

## 字段说明

- **interaction_id**：稳定 ID 字段。例：Interactable 通过 interaction_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **display_text**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。

## 接口

```gdscript
class_name Interactable
extends Node
@export var interaction_id: String = ""
@export var display_text: String = "Interact"
@export var conditions: Array[Condition] = []
func can_interact(context: GameplayContext) -> bool
func interact(context: GameplayContext) -> bool
```

## 函数使用场景

- **`can_interact(context)`**：通过 ConditionEvaluator 检查所有条件，返回是否允许互动。InteractionComponent 进入范围时和玩家按键时调用此方法，决定是否显示提示和允许触发。
- **`interact(context)`**：互动主入口，先调用 `can_interact()`，通过后调用 `_interact_impl()`。InteractionComponent.try_interact() 调用此方法。
- **`_interact_impl(context)`**：子类重写此方法实现具体互动逻辑，例如宝箱发放物品、门打开场景、NPC 开始对话。

## 使用示例

### 宝箱互动（子类示例）

```gdscript
class_name ChestInteractable
extends Interactable

@export var loot_table_id: String = "loot.chest_common"
var opened: bool = false

func _interact_impl(context: GameplayContext) -> bool:
    if opened:
        return false
    opened = true

    var loot := LootSystem.new().roll_table(loot_table_id, context)
    var inventory := context.source.get_node("Controllers/InventoryController") as InventoryController
    for item in loot.item_instances:
        inventory.add_item(item)

    return true
```
