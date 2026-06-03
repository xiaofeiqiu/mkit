# DialogueChoice

## 概念说明

DialogueChoice 是分支节点中的一个玩家选项：选项文本、跳转目标节点、可见/可选条件，以及选择时执行的 effects。

## 设计目的

让「选项是否出现」和「选了会发生什么」复用既有的 Condition 与 GameEffect 机制，而不发明对话专用的判定/副作用系统。一个选项既能接任务（AcceptQuestEffect）、给物品（GrantItemEffect），也能仅做跳转。

## 文件

`res://addons/mkit/modules/dialogue/dialogue_choice.gd`

## 字段说明

- **text**：选项展示文本（多行）。
- **next_node_id**：选择后跳转的节点 ID；为空表示选择后结束对话。
- **conditions**：可见/可选条件列表。DialogueController 用 ConditionEvaluator 过滤；未全部满足的选项不出现在 get_available_choices() 结果中。
- **effects**：选择时由 EffectExecutor 执行的 GameEffect 列表。

## 接口

```gdscript
class_name DialogueChoice
extends Resource
@export_multiline var text: String = ""
@export var next_node_id: String = ""
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []
```

## 函数使用场景

DialogueChoice 是纯数据 Resource，无公开方法。运行时由 DialogueController 读取：

- **条件选项**：在 `conditions` 挂条件（例如「任务未接取时才显示『我接』」），不满足时该选项被过滤掉。
- **副作用选项**：在 `effects` 挂 AcceptQuestEffect / CompleteQuestEffect / GrantItemEffect 等，选择时执行。
- **纯跳转选项**：只设 `next_node_id`。

## 使用示例

```gdscript
var accept := DialogueChoice.new()
accept.text = "I'll take the quest"
accept.next_node_id = "n.thanks"
var accept_quest := AcceptQuestEffect.new()
accept_quest.quest_id = "quest.errand"
accept.effects = [accept_quest]
```
