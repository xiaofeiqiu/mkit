class_name DialogueNode
extends Resource
## 说明：`DialogueNode` 是 对话系统 的节点数据，负责保存图或流程中的单个节点信息。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在对话系统中复用这段契约或状态时使用它。
## 示例：`var instance := DialogueNode.new()`

## DialogueDefinition 内部引用该节点的稳定 id；同一对话资源内应保持唯一。
@export var node_id: String = ""
## 该节点发言者 id；UI 可用它查找头像、名称或站位。
@export var speaker_id: String = ""
## 对话选项或节点展示文本；可为空但 UI 应处理空文本。
@export_multiline var text: String = ""
## 进入该对话节点时执行的效果列表。
@export var on_enter_effects: Array[GameEffect] = []
## 该节点可选择的分支列表；为空时表示线性节点或结束节点。
@export var choices: Array[DialogueChoice] = []
## 选择后跳转到的 DialogueNode id；为空表示对话结束或保持在当前节点。
@export var next_node_id: String = ""
