# EntitySaveAgent

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/entity_save_agent.gd`  
**继承：** `extends Node`

## 职责

实体级存档聚合器。`SaveService.save_game(root)` 会收集场景树中的 `EntitySaveAgent`，用 `entity_id` 写入 `entities[entity_id]`，再由 agent 收集所属实体下的组件数据。

它解决两个问题：

- `SaveService` 仍然是唯一存读档入口。
- 实体组件不会平铺成全局 key，而是落在稳定实体 id 下的 `components` 字段。

生成结构：

```json
{
  "entities": {
    "player": {
      "scene_path": "res://game/entities/player.tscn",
      "zone_id": "village",
      "components": {
        "HealthComponent": {},
        "InventoryController": {}
      }
    }
  }
}
```

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `entity_id` | `String`（@export）| `""` | 稳定实体 id；在 `entities` 内唯一 |
| `scene_path` | `String`（@export）| `""` | 可选实体场景路径，供后续重建实体使用 |
| `zone_id` | `String`（@export）| `""` | 可选区域 id，供世界/区域恢复使用 |
| `root_path` | `NodePath`（@export）| `NodePath("")` | 可选实体根；为空时用 `owner`，再回退 `get_parent()` |
| `restore_order` | `int`（@export）| `0` | 读档排序；数值小的先恢复 |
| `include_duck_participants` | `bool`（@export）| `true` | 是否收集 duck-typed 组件 participant |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_entity_id() -> String` | `String` | 返回去空白后的 `entity_id` |
| `to_entity_save_record() -> Dictionary` | `Dictionary` | 收集实体组件并返回实体记录 |
| `apply_entity_save_record(record: Dictionary) -> void` | `void` | 根据 `record.components` 回填组件 |
| `has_save_errors() -> bool` | `bool` | 最近一次收集/恢复是否有错误 |
| `get_save_errors() -> Array[String]` | `Array[String]` | 返回最近一次错误列表 |

## 组件收集

`EntitySaveAgent` 收集两类组件：

- `node is SaveableComponent`
- 在 `"mkit_entity_save_participant"` group 中，且同时实现 `get_save_key()`、`to_save_data()`、`from_save_data(data)` 的节点

第二类用于 GDScript 单继承冲突：一个节点已经继承了别的组件基类，但仍需要被实体存档收集。

```gdscript
extends Node

var opened: bool = false

func _ready() -> void:
    add_to_group(EntitySaveAgent.ENTITY_SAVE_PARTICIPANT_GROUP)

func get_save_key() -> String:
    return "ChestState"

func to_save_data() -> Dictionary:
    return {"opened": opened}

func from_save_data(data: Dictionary) -> void:
    opened = bool(data.get("opened", false))
```

## 使用模式

### 最小示例（Level 1）

在玩家实体场景下加一个 `EntitySaveAgent` 子节点：

```text
Player
  Components/
    HealthComponent
    StatsComponent
  Controllers/
    InventoryController
  EntitySaveAgent
```

Inspector:

```text
entity_id = "player"
scene_path = "res://game/entities/player.tscn"
zone_id = "village"
```

`HealthComponent`、`StatsComponent`、`InventoryController` 继承 `SaveableComponent`，会自动进入 `entities.player.components`。

### 典型场景（Level 2）

```gdscript
var save := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
if save.save_game(get_tree().root):
    print("saved")
```

`SaveService` 会同时保存全局 `roots` 和实体 `entities`。读档时先恢复 `roots`，再按 `EntitySaveAgent.restore_order` 恢复实体组件。

## 相关

- → [SaveService](SaveService.md) · [SaveableComponent](SaveableComponent.md) · [Saveable](Saveable.md)
- → [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md)
