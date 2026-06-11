class_name DialogueNode
extends Resource
## 说明：`DialogueNode` 是 对话系统 的节点数据，负责保存图或流程中的单个节点信息。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在对话系统中复用这段契约或状态时使用它。
## 示例：`var instance := DialogueNode.new()`

## 编辑器配置：`node_id` 表示稳定 id，由 `DialogueNode` 的公开 API 读取或维护。
@export var node_id: String = ""
## 编辑器配置：`speaker_id` 表示稳定 id，由 `DialogueNode` 的公开 API 读取或维护。
@export var speaker_id: String = ""
## 编辑器配置：`text` 表示 `DialogueNode` 的字段值，由 `DialogueNode` 的公开 API 读取或维护。
@export_multiline var text: String = ""
## 编辑器配置：`on_enter_effects` 表示效果列表，由 `DialogueNode` 的公开 API 读取或维护。
@export var on_enter_effects: Array[GameEffect] = []
## 编辑器配置：`choices` 表示 `DialogueNode` 的字段值，由 `DialogueNode` 的公开 API 读取或维护。
@export var choices: Array[DialogueChoice] = []
## 编辑器配置：`next_node_id` 表示稳定 id，由 `DialogueNode` 的公开 API 读取或维护。
@export var next_node_id: String = ""
