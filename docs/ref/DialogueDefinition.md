# DialogueDefinition

## 概念说明

DialogueDefinition 是一段对话的静态 Resource 配置：一个对话 ID、起始节点 ID，以及组成对话树的全部 DialogueNode。它是 NPC「说什么、怎么分支」的数据载体。

## 设计目的

让对话完全数据驱动。具体的台词、分支结构、选项接什么任务都是 `game/` 里的 `.tres` 内容，addon 只定义结构与索引方式。DialogueController 通过 ContentRegistry 按 dialogue_id 取出本定义后运行，定义本身不持有任何运行时状态。

## 文件

`res://addons/mkit/modules/dialogue/dialogue_definition.gd`

## 字段说明

- **dialogue_id**：对话的稳定 ID，供 ContentRegistry 索引（需在 `_extract_content_id` 列表登记，已含 `dialogue_id`）。
- **start_node_id**：起始节点 ID。DialogueController.start() 进入此节点。
- **nodes**：对话树的全部 DialogueNode。节点之间通过 next_node_id 或 DialogueChoice.next_node_id 引用，按 node_id 查找。

## 接口

```gdscript
class_name DialogueDefinition
extends Resource
@export var dialogue_id: String = ""
@export var start_node_id: String = ""
@export var nodes: Array[DialogueNode] = []
func get_resource_id() -> String
func get_node(node_id: String) -> DialogueNode
```

## 函数使用场景

- **`get_resource_id()`**：返回 dialogue_id，供 ContentRegistry 注册与查询。
- **`get_node(node_id)`**：按 node_id 在 nodes 中线性查找对应 DialogueNode；DialogueController 进入/推进节点时调用，未找到返回 null（控制器据此结束对话）。

## 使用示例

```gdscript
var greeting := DialogueNode.new()
greeting.node_id = "n.greet"
greeting.text = "Welcome to the village."

var dialogue := DialogueDefinition.new()
dialogue.dialogue_id = "dlg.elder_intro"
dialogue.start_node_id = "n.greet"
dialogue.nodes = [greeting]
```
