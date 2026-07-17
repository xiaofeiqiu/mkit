class_name DialogueChoice
extends Resource
## 说明：`DialogueChoice` 是 对话系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在对话系统中复用这段契约或状态时使用它。
## 示例：`var instance := DialogueChoice.new()`

## 对话选项或节点展示文本；可为空但 UI 应处理空文本。
@export_multiline var text: String = ""
## 选择后跳转到的 DialogueNode id；为空表示对话结束或保持在当前节点。
@export var next_node_id: String = ""
## 执行前按顺序求值的条件列表；任一条件失败时阻止本对象继续产生效果。
@export var conditions: Array[Condition] = []
## 条件通过后按顺序执行的效果列表；每个元素应为 GameEffect 资源。
@export var effects: Array[GameEffect] = []
