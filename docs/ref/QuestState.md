# QuestState

## 概念说明

QuestState 是单个任务的运行时状态。它保存任务状态和每个 objective 的当前进度，是 QuestSystem 持久化任务进度的基本单元。

## 设计目的

把静态 QuestDefinition 与运行时进度分离，避免把可变进度写回共享 Resource。

## 文件

`res://addons/mkit/modules/quest/quest_state.gd`

## 字段说明

- **quest_id**：对应 QuestDefinition.quest_id。
- **status**：任务运行状态。当前实现使用 `available`、`active`、`completed`、`turned_in`，设计上保留 `locked` 和 `failed` 供游戏侧扩展。
- **objective_progress**：目标进度字典，key 为 QuestObjectiveDefinition.objective_id，value 为当前计数。

## 接口

```gdscript
class_name QuestState
extends RefCounted
var quest_id: String = ""
var status: String = "available"
var objective_progress: Dictionary = {}
static func create(quest_id: String) -> QuestState
func get_progress(objective_id: String) -> int
func set_progress(objective_id: String, value: int) -> void
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`create(quest_id)`**：QuestSystem 接取新任务时创建默认状态。
- **`get_progress(objective_id)`**：UI、测试或系统查询目标当前进度。
- **`set_progress(objective_id, value)`**：QuestSystem 推进目标时写入非负进度；负数会被归零。
- **`to_save_data()`**：输出 quest_id、status 和 objective_progress 的 Dictionary。
- **`from_save_data(data)`**：恢复任务状态，并把 objective_progress 的值转换为 int。

## 使用示例

```gdscript
var state := QuestState.create("quest.intro")
state.status = "active"
state.set_progress("obj.talk", 1)
var saved := state.to_save_data()
```
