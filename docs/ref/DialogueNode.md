# DialogueNode

## 概念说明

DialogueNode 是对话中的一屏：说话人、台词、进入时执行的 effects，以及后继（线性 next_node_id 或分支 choices）。

## 设计目的

把「一句话 + 它之后发生什么」表达为纯数据。进入节点时可触发副作用（on_enter_effects），后继既可线性也可分支，让同一套结构既能写线性叙事也能写选项树，不必为两种形态各写一套类型。

## 文件

`res://addons/mkit/modules/dialogue/dialogue_node.gd`

## 字段说明

- **node_id**：节点在所属 DialogueDefinition 内的唯一 ID。
- **speaker_id**：说话人标识，供 UI 显示名字/头像；纯展示用，不参与逻辑。
- **text**：本屏台词（多行）。
- **on_enter_effects**：进入该节点时由 EffectExecutor 执行的 GameEffect 列表（例如给提示物品、发自定义事件）。
- **choices**：分支选项。非空时呈现选项，玩家须 choose 推进。
- **next_node_id**：线性后继节点 ID。仅当 choices 为空时生效；为空表示该节点是终点，advance 时结束对话。

## 接口

```gdscript
class_name DialogueNode
extends Resource
@export var node_id: String = ""
@export var speaker_id: String = ""
@export_multiline var text: String = ""
@export var on_enter_effects: Array[GameEffect] = []
@export var choices: Array[DialogueChoice] = []
@export var next_node_id: String = ""
```

## 函数使用场景

DialogueNode 是纯数据 Resource，无公开方法。运行时由 DialogueController 读取：

- **线性节点**：填 `next_node_id`、留空 `choices`，玩家按 advance 逐屏推进。
- **分支节点**：填 `choices`，玩家须 choose 一个选项；此时 next_node_id 被忽略。
- **终点节点**：`choices` 与 `next_node_id` 都为空，advance 即结束对话。

## 使用示例

```gdscript
var node := DialogueNode.new()
node.node_id = "n.offer"
node.speaker_id = "elder"
node.text = "Will you help the village?"

var accept := DialogueChoice.new()
accept.text = "Yes"
node.choices = [accept]
```
