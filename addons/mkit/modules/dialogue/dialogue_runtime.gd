class_name DialogueRuntime
extends RefCounted
## 说明：`DialogueRuntime` 是 对话系统 的运行时模型，负责保存当前流程执行中的临时状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在对话系统中复用这段契约或状态时使用它。
## 示例：`var instance := DialogueRuntime.new()`

## 运行时状态：`dialogue_id` 表示稳定 id，由 `DialogueRuntime` 的公开 API 读取或维护。
var dialogue_id: String = ""
## 运行时状态：`current_node_id` 表示稳定 id，由 `DialogueRuntime` 的公开 API 读取或维护。
var current_node_id: String = ""
## 运行时状态：`history` 表示 `DialogueRuntime` 的字段值，由 `DialogueRuntime` 的公开 API 读取或维护。
var history: Array[String] = []
## 运行时状态：`context` 表示 `DialogueRuntime` 的字段值，由 `DialogueRuntime` 的公开 API 读取或维护。
var context: GameplayContext = null
