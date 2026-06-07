# QuestDefinition

**层：** Module  
**文件：** `addons/mkit/modules/quest/quest_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

任务静态配置。定义目标、前置任务、接取条件、奖励 effect，以及是否自动完成 / 可重复。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `quest_id` | `String`（@export）| `""` | 内容 ID，`get_content_id()` 返回它 |
| `display_name` | `String`（@export）| `""` | UI 显示名 |
| `description` | `String`（@export_multiline）| `""` | 任务描述 |
| `quest_type` | `String`（@export）| `"side"` | 类型标签 |
| `objectives` | `Array[QuestObjectiveDefinition]`（@export）| `[]` | 目标列表 |
| `prerequisite_quest_ids` | `Array[String]`（@export）| `[]` | 必须已 turned_in 的任务 |
| `accept_conditions` | `Array[Condition]`（@export）| `[]` | 接取条件 |
| `reward_effects` | `Array[GameEffect]`（@export）| `[]` | 交付奖励 |
| `auto_complete` | `bool`（@export）| `false` | 目标达成时是否自动 complete |
| `repeatable` | `bool`（@export）| `false` | turned_in 后是否回到 available |
| `tags` | `Array[String]`（@export）| `[]` | 分类标签 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_content_id() -> String` | `String` | 返回 `quest_id` |
| `get_objective(objective_id: String) -> QuestObjectiveDefinition` | `QuestObjectiveDefinition` | 查找目标，找不到返回 `null` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var quest: QuestDefinition = content.get_resource("quest.first_hunt") as QuestDefinition
var objective: QuestObjectiveDefinition = quest.get_objective("kill_enemy")
```

### 典型场景（Level 2）

```gdscript
func can_offer_quest(quest_id: String, player: Node) -> bool:
    var quest_service: QuestService = ServiceRegistry.get_service("quest") as QuestService
    if quest_service == null:
        return false
    var ctx := GameplayContext.new()
    ctx.source = player
    return quest_service.can_accept(quest_id, ctx)
```

## 相关

- → [QuestObjectiveDefinition](QuestObjectiveDefinition.md) · [QuestService](QuestService.md) · [AcceptQuestEffect](AcceptQuestEffect.md)
- → [cookbook/10_quest.md](../../cookbook/10_quest.md)

