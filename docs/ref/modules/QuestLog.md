# QuestLog

**层：** Module  
**文件：** `addons/mkit/modules/quest/quest_log.gd`  
**继承：** `extends RefCounted`

## 职责

任务状态容器。由 `QuestService` 持有，集中查询 active 任务，并负责把所有 `QuestState` 序列化进存档。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `states` | `Dictionary` | `{}` | quest_id → `QuestState` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_state(quest_id: String) -> QuestState` | `QuestState` | 查状态，找不到返回 `null` |
| `has(quest_id: String) -> bool` | `bool` | 是否已有状态 |
| `get_active() -> Array[QuestState]` | `Array[QuestState]` | 返回所有 `status == "active"` 的任务 |
| `to_save_data() -> Dictionary` | `Dictionary` | 序列化全部状态 |
| `from_save_data(data: Dictionary) -> void` | — | 反序列化全部状态 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var quest: QuestService = ServiceRegistry.get_service("quest") as QuestService
var active: Array[QuestState] = quest.log.get_active()
```

### 典型场景（Level 2）

```gdscript
func list_active_quests() -> void:
    var quest: QuestService = ServiceRegistry.get_service("quest") as QuestService
    if quest == null:
        return
    for state in quest.log.get_active():
        print("%s %s" % [state.quest_id, state.status])
```

## 相关

- → [QuestState](QuestState.md) · [QuestService](QuestService.md) · [SaveService](../kernel/SaveService.md)

