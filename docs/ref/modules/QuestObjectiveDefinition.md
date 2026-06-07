# QuestObjectiveDefinition

**层：** Module  
**文件：** `addons/mkit/modules/quest/quest_objective_definition.gd`  
**继承：** `extends Resource`

## 职责

任务目标配置。`QuestService` 用它匹配 `DomainEvent`，并把匹配事件转成目标进度。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `objective_id` | `String`（@export）| `""` | 目标键，存档进度按它记录 |
| `description` | `String`（@export_multiline）| `""` | UI 文案 |
| `event_type` | `String`（@export）| `""` | 要匹配的 `DomainEvent.event_type` |
| `match_key` | `String`（@export）| `""` | payload 匹配字段；空表示只匹配事件类型 |
| `match_value` | `String`（@export）| `""` | payload 值；若 actual 是 Array，则使用 `has()` |
| `count_payload_key` | `String`（@export）| `""` | 从 payload 读取推进数量；空则每次 +1 |
| `required_count` | `int`（@export）| `1` | 完成所需数量 |
| `optional` | `bool`（@export）| `false` | 可选目标不阻塞 `is_quest_complete()` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var objective := QuestObjectiveDefinition.new()
objective.objective_id = "kill_enemy"
objective.event_type = "enemy_killed"
objective.match_key = "faction"
objective.match_value = "enemy"
objective.required_count = 3
```

### 典型场景（Level 2）

```gdscript
func add_item_objective(quest: QuestDefinition) -> void:
    var objective := QuestObjectiveDefinition.new()
    objective.objective_id = "collect_key"
    objective.event_type = "item_acquired"
    objective.match_key = "item_id"
    objective.match_value = "item.key"
    objective.count_payload_key = "amount"
    objective.required_count = 1
    quest.objectives.append(objective)
```

## 相关

- → [QuestDefinition](QuestDefinition.md) · [QuestService](QuestService.md) · [DomainEvent](../kernel/DomainEvent.md)
- → [pipeline.md — Quest Lifecycle](../../pipeline.md#12-quest-lifecycle)

