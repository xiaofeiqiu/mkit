# QuestState

**层：** Module  
**文件：** `addons/mkit/modules/quest/quest_state.gd`  
**继承：** `extends RefCounted`

## 职责

任务运行时状态。保存当前任务状态和每个 objective 的进度，供 `QuestLog` 和 `QuestService` 持久化。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `quest_id` | `String` | `""` | 对应 `QuestDefinition.quest_id` |
| `status` | `String` | `"available"` | `available` / `active` / `completed` / `turned_in` |
| `objective_progress` | `Dictionary` | `{}` | objective_id → 当前数量 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static create(quest_id: String) -> QuestState` | `QuestState` | 创建并写入 quest_id |
| `get_progress(objective_id: String) -> int` | `int` | 读取进度，默认 0 |
| `set_progress(objective_id: String, value: int) -> void` | — | 写进度，最小为 0 |
| `to_save_data() -> Dictionary` | `Dictionary` | 序列化 |
| `from_save_data(data: Dictionary) -> void` | — | 反序列化 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var state := QuestState.create("quest.first_hunt")
state.status = "active"
state.set_progress("kill_enemy", 1)
```

### 典型场景（Level 2）

```gdscript
func print_progress(quest_id: String, objective_id: String) -> void:
    var quest: QuestService = ServiceRegistry.get_service("quest") as QuestService
    var state: QuestState = quest.get_state(quest_id)
    if state == null:
        return
    print("%s: %d" % [objective_id, state.get_progress(objective_id)])
```

## 相关

- → [QuestLog](QuestLog.md) · [QuestService](QuestService.md) · [QuestObjectiveDefinition](QuestObjectiveDefinition.md)

