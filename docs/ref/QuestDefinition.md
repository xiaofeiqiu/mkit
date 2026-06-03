# QuestDefinition

## 概念说明

QuestDefinition 是任务的静态 Resource 配置。它描述任务 ID、展示文本、目标列表、前置任务、接取条件、奖励 effects 和完成方式。具体任务内容由游戏项目在 `game/` 中创建资源，addon 只提供通用结构。

## 设计目的

让任务可以通过数据组合战斗、拾取、对话、区域进入和奖励流程，而不是在系统代码中硬编码任务规则。

## 文件

`res://addons/mkit/modules/quest/quest_definition.gd`

## 字段说明

- **quest_id**：任务稳定 ID。例：`quest.intro`，供 ContentRegistry、存档和 QuestSystem 查找。
- **display_name**：任务显示名称。UI 可直接读取。
- **description**：任务描述文本。用于任务日志或对话提示。
- **quest_type**：任务分类。例：`main`、`side`，由具体游戏内容约定。
- **objectives**：任务目标列表。每个元素是 QuestObjectiveDefinition。
- **prerequisite_quest_ids**：前置任务 ID 列表。只有这些任务都 `turned_in` 后才能接取。
- **accept_conditions**：接取条件列表。QuestSystem.can_accept 会通过 ConditionEvaluator 统一校验。
- **reward_effects**：完成或 turn-in 时执行的奖励 effects。例：GrantItemEffect、升级货币 effect 或游戏自定义 effect。
- **auto_complete**：所有必需目标完成后是否自动完成并尝试发奖。
- **repeatable**：turn-in 后是否重置为可再次接取。
- **tags**：任务标签。用于 UI 分类或游戏侧筛选。

## 接口

```gdscript
class_name QuestDefinition
extends Resource
@export var quest_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var quest_type: String = "side"
@export var objectives: Array[QuestObjectiveDefinition] = []
@export var prerequisite_quest_ids: Array[String] = []
@export var accept_conditions: Array[Condition] = []
@export var reward_effects: Array[GameEffect] = []
@export var auto_complete: bool = false
@export var repeatable: bool = false
@export var tags: Array[String] = []
func get_resource_id() -> String
func get_objective(objective_id: String) -> QuestObjectiveDefinition
```

## 函数使用场景

- **`get_resource_id()`**：返回 `quest_id`，供 ContentRegistry 使用稳定 ID 索引任务定义。
- **`get_objective(objective_id)`**：QuestSystem 和任务 effects 需要按 objective_id 查找目标定义时使用；找不到时返回 null。

## 使用示例

```gdscript
var objective := QuestObjectiveDefinition.new()
objective.objective_id = "obj.herbs"
objective.event_type = "item_acquired"
objective.match_key = "item_id"
objective.match_value = "item.herb"
objective.count_payload_key = "amount"
objective.required_count = 5

var grant_reward := GrantItemEffect.new()
grant_reward.item_id = "item.potion_small"
grant_reward.quantity = 2

var quest := QuestDefinition.new()
quest.quest_id = "quest.intro"
quest.objectives = [objective]
quest.reward_effects = [grant_reward]
quest.auto_complete = true
```
