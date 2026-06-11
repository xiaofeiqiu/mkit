class_name DialogueChoice
extends Resource
## 说明：`DialogueChoice` 是 对话系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在对话系统中复用这段契约或状态时使用它。
## 示例：`var instance := DialogueChoice.new()`

## 编辑器配置：`text` 表示 `DialogueChoice` 的字段值，由 `DialogueChoice` 的公开 API 读取或维护。
@export_multiline var text: String = ""
## 编辑器配置：`next_node_id` 表示稳定 id，由 `DialogueChoice` 的公开 API 读取或维护。
@export var next_node_id: String = ""
## 编辑器配置：`conditions` 表示执行条件列表，由 `DialogueChoice` 的公开 API 读取或维护。
@export var conditions: Array[Condition] = []
## 编辑器配置：`effects` 表示效果列表，由 `DialogueChoice` 的公开 API 读取或维护。
@export var effects: Array[GameEffect] = []
