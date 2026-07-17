class_name DialogueRuntime
extends RefCounted
## 说明：`DialogueRuntime` 是 对话系统 的运行时模型，负责保存当前流程执行中的临时状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在对话系统中复用这段契约或状态时使用它。
## 示例：`var instance := DialogueRuntime.new()`

## 引用的 DialogueDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
var dialogue_id: String = ""
## 引用的 current node id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
var current_node_id: String = ""
## 运行时经过的对话节点 id 历史；用于回放、调试或防重复。
var history: Array[String] = []
## 当前执行上下文；动作启动后供阶段逻辑、条件和效果读取。
var context: GameplayContext = null
