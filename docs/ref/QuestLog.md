# QuestLog

## 概念说明

QuestLog 是玩家任务状态集合，按 quest_id 保存多个 QuestState。QuestSystem 通过它查询 active 任务、保存任务进度和恢复存档。

## 设计目的

把任务集合的序列化和索引逻辑集中在一个运行时对象中，QuestSystem 负责规则，QuestLog 负责数据容器。

## 文件

`res://addons/mkit/modules/quest/quest_log.gd`

## 字段说明

- **states**：任务状态字典，key 为 quest_id，value 为 QuestState。

## 接口

```gdscript
class_name QuestLog
extends RefCounted
var states: Dictionary = {}
func get_state(quest_id: String) -> QuestState
func has(quest_id: String) -> bool
func get_active() -> Array[QuestState]
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`get_state(quest_id)`**：QuestSystem、UI 或测试查询某个任务状态；不存在时返回 null。
- **`has(quest_id)`**：判断日志中是否已有该任务状态。
- **`get_active()`**：QuestSystem 处理事件时只遍历 active 任务。
- **`to_save_data()`**：把每个 QuestState 序列化到 `states` 字段下。
- **`from_save_data(data)`**：从存档 Dictionary 重建 QuestState 集合。

## 使用示例

```gdscript
var log := QuestLog.new()
log.states["quest.intro"] = QuestState.create("quest.intro")
log.states["quest.intro"].status = "active"
var active := log.get_active()
var saved := log.to_save_data()
```
