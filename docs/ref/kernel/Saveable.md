# Saveable

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/saveable.gd`  
**继承：** `extends Node`

## 职责

**全局存档契约**。`SaveService.save_game(root)` 遍历场景树，自动收集**所有 `Saveable` 节点**，按 `get_save_id()` 归档。适合全局状态：玩家存档根、`QuestService`、`ProgressionService`、`ExperienceComponent` 等。

> 对比 [SaveableComponent](SaveableComponent.md)：后者**不会**被 `SaveService` 自动收集。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `save_id` | `String`（@export）| `""` | 存档键，**全局唯一**；空则回退到 `owner.name`/`name` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_save_id() -> String` | `String` | 返回 `save_id`，为空时回退节点名 |
| `to_save_data() -> Dictionary` | `Dictionary` | **override** 返回要存的数据，默认 `{}` |
| `from_save_data(data: Dictionary) -> void` | — | **override** 从数据恢复 |

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name GameClock
extends Saveable
# save_id = "clock"

var day: int = 1

func to_save_data() -> Dictionary:
    return {"day": day}

func from_save_data(data: Dictionary) -> void:
    day = int(data.get("day", 1))
```

### 典型场景（Level 2）

```gdscript
# 玩家存档代理：把实体里的 SaveableComponent 收集进同一份 "player" 存档
class_name PlayerSaveAgent
extends Saveable
# Inspector: save_id = "player"


func to_save_data() -> Dictionary:
    var data: Dictionary = {}
    var root := owner if owner != null else get_parent()
    for node in root.find_children("*", "", true, false):
        if node is SaveableComponent:
            var comp := node as SaveableComponent
            data[comp.get_save_key()] = comp.to_save_data()
    return data


func from_save_data(data: Dictionary) -> void:
    var root := owner if owner != null else get_parent()
    for node in root.find_children("*", "", true, false):
        if node is SaveableComponent:
            var comp := node as SaveableComponent
            if data.has(comp.get_save_key()):
                comp.from_save_data(data[comp.get_save_key()])
```

## 相关

- → [SaveableComponent](SaveableComponent.md)（组件级契约，需被收集）· [SaveService](SaveService.md)
- → [concepts.md — 模型 4：两条存档契约](../../concepts.md#模型-4两条存档契约) · [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md)
