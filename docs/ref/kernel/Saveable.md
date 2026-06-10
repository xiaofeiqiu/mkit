# Saveable

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/saveable.gd`  
**继承：** `extends Node`

## 职责

**全局/root 级存档契约**。

`SaveService.save_game` 会收集 `Saveable` 节点并写入 `roots`；阶段性地通过 `get_save_scopes()` 写入结构化 scope 字段（用于无场景树恢复）。

可用于全局状态：`QuestService`、`ProgressionService`、`ExperienceComponent`、`WorldService`、`AudioService` 等。

> 对比 [EntitySaveAgent](EntitySaveAgent.md)：实体内的 `SaveableComponent` 应落在 `entities[entity_id].components`，不要把组件平铺成全局 `roots` key。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `save_id` | `String`（@export）| `""` | 存档键，**全局唯一**；空则回退到 `owner.name`/`name` |
| `save_scope` | `String`（@export）| `""` | scope 名；空则为 `"global"` |
| `restore_order` | `int`（@export）| `0` | 读档排序；数值小的先恢复 |

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

### Scope 恢复（Level 2）

```gdscript
class_name WorldSnapshot
extends Saveable

func _ready() -> void:
    save_id = "world"
    save_scope = "world.zone"

func to_save_data() -> Dictionary:
    return {"zone_id": "village"}

func from_save_data(data: Dictionary) -> void:
    print("restore zone: %s" % str(data.get("zone_id", "")))
```

`get_save_scopes()` 与 `get_save_payload_for_scope(...)` 在需要“场景树未恢复也要还原状态”的模块里使用，当前世界流程（`RunDirector`/`WorldService`）就是典型用例。

## 相关

- → [EntitySaveAgent](EntitySaveAgent.md)（实体级聚合器）· [SaveableComponent](SaveableComponent.md)（组件级契约）· [SaveService](SaveService.md)
- → [concepts.md — 存档：两条契约](../../concepts.md#六、存档：两条契约) · [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md)
