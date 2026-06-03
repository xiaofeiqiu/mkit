# QuestObjectiveDefinition

## 概念说明

QuestObjectiveDefinition 是一个任务目标的静态配置。它用事件类型、payload 匹配条件和计数规则表达目标进度，例如击败带某个 tag 的实体、获得指定物品、到达指定 zone 或与 NPC 对话。

## 设计目的

用统一的事件匹配模型覆盖不同任务目标，避免为每一种目标新增专用代码。

## 文件

`res://addons/mkit/modules/quest/quest_objective_definition.gd`

## 字段说明

- **objective_id**：目标稳定 ID，在一个 QuestDefinition 内唯一。QuestState.objective_progress 使用它作为 key。
- **description**：目标描述文本。任务日志可展示给玩家。
- **event_type**：目标监听的 DomainEvent 类型。例：`enemy_killed`、`item_acquired`、`npc_talked`、`zone_changed`。
- **match_key**：可选 payload 字段名。为空时只按 event_type 匹配。
- **match_value**：match_key 对应字段的目标值。payload 字段是 Array 时，QuestSystem 会检查数组是否包含该值。
- **count_payload_key**：可选计数字段。为空时每个匹配事件增加 1；非空时读取 payload 中的数量。
- **required_count**：目标需要达到的进度。QuestSystem 推进时会 clamp 到此上限。
- **optional**：是否为可选目标。可选目标不影响 QuestSystem.is_quest_complete。

## 接口

```gdscript
class_name QuestObjectiveDefinition
extends Resource
@export var objective_id: String = ""
@export_multiline var description: String = ""
@export var event_type: String = ""
@export var match_key: String = ""
@export var match_value: String = ""
@export var count_payload_key: String = ""
@export var required_count: int = 1
@export var optional: bool = false
```

## 函数使用场景

QuestObjectiveDefinition 是纯数据 Resource，无公开方法。字段由 Inspector 配置后随 QuestDefinition 注册到 ContentRegistry。

- **击杀目标**：`event_type="enemy_killed"`，`match_key="tags"`，`match_value="beast"`，可匹配 EntityIdentity.tags。
- **收集目标**：`event_type="item_acquired"`，`match_key="item_id"`，`match_value="item.herb"`，`count_payload_key="amount"`。
- **对话目标**：`event_type="npc_talked"`，`match_key="npc_id"`，`match_value` 指向具体内容层 NPC ID。
- **区域目标**：`event_type="zone_changed"`，`match_key="to_zone_id"`，`match_value` 指向具体内容层 zone ID。

## 使用示例

```gdscript
var objective := QuestObjectiveDefinition.new()
objective.objective_id = "obj.herbs"
objective.event_type = "item_acquired"
objective.match_key = "item_id"
objective.match_value = "item.herb"
objective.count_payload_key = "amount"
objective.required_count = 5
```
