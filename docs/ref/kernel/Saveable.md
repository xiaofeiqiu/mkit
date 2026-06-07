# Saveable

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/saveable.gd`  
**继承：** `extends Node`

## 职责

**全局存档契约**。

`SaveService.save_game` 会收集 `Saveable` 节点；阶段性地通过 `get_save_scopes()` 写入结构化 scope 字段（用于无场景树恢复）。

可用于全局状态：玩家状态根、`QuestService`、`ProgressionService`、`ExperienceComponent` 等。

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
| `get_save_scopes() -> Array[String]` | `Array[String]` | 仅 scope 模式时需覆盖，默认返回 `get_save_scope()` |
| `get_save_payload_for_scope(scope: String) -> Dictionary` | `Dictionary` | 指定 scope 的持久化载荷 |
| `apply_save_payload_for_scope(scope: String, data: Dictionary) -> bool` | `bool` | 指定 scope 恢复，返回是否已处理 |

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

func _ready() -> void:
    # 可选：声明这个玩家存档属于 scene/state 域
    save_scope = "player"

func to_save_data() -> Dictionary:
    var data: Dictionary = {}
    # owner = 玩家场景根；遍历其下所有 SaveableComponent
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
            var key := comp.get_save_key()  # 默认是节点 name
            if data.has(key):
                comp.from_save_data(data[key])
```

`get_save_scopes()` 与 `get_save_payload_for_scope(...)` 在需要“场景树未恢复也要还原状态”的模块里使用，当前世界流程（`RunDirector`/`WorldService`）就是典型用例。

## 相关

- → [SaveableComponent](SaveableComponent.md)（组件级契约，需被收集）· [SaveService](SaveService.md)
- → [concepts.md — 存档：两条契约](../../concepts.md#六、存档：两条契约) · [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md)
