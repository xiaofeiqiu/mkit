class_name GameCommand
extends RefCounted
## 说明：`GameCommand` 是 命令路由 的命令对象，负责承载输入、AI 或脚本发出的意图。
## 上游：通常由输入、AI、脚本或 CommandService 创建或调用。
## 下游：会连接CommandReceiver、StateMachine 或目标实体，不直接依赖具体游戏内容。
## 使用：当项目调用方只想表达意图，并交给 pipeline 决定如何处理时使用它。
## 示例：`var instance := GameCommand.new()`

## 引用的 命令 id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
var command_id: String = ""
## 命令类型字符串；接收方按该值选择处理逻辑。
var command_type: String = ""
## 事件、命令或修饰器来源 id；通常对应 EntityIdentity、系统或内容定义。
var source_id: String = ""
## 事件或命令目标 id；CommandService 可用它定位接收者。
var target_id: String = ""
## 事件或命令创建时的时间戳，单位为秒；用于排序、调试和历史记录。
var timestamp: float = 0.0
## 附加上下文数据；key 由创建该对象的系统约定，读取前应检查是否存在。
var payload: Dictionary = {}
## 命令是否已经被接收方消费；为 true 后调用方不应重复路由。
var consumed: bool = false


## 创建并返回新的运行时对象；返回值、signal 或事件会表达实际执行结果。
static func create(
	type: String, source: String = "", target: String = "", data: Dictionary = {}
) -> GameCommand:
	var cmd := GameCommand.new()
	cmd.command_type = type
	cmd.command_id = "%s_%d" % [type, Time.get_ticks_usec()]
	cmd.source_id = source
	cmd.target_id = target
	cmd.timestamp = Time.get_ticks_msec() / 1000.0
	cmd.payload = data
	return cmd


## 执行 `mark_consumed` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func mark_consumed() -> void:
	consumed = true


## 读取当前对象中的 `vector2`；未找到时返回 null、空集合或该 API 的默认值。
func get_vector2(key: String, default_value: Vector2 = Vector2.ZERO) -> Vector2:
	if payload.has(key):
		return payload[key]
	return default_value


## 读取当前对象中的 `string`；未找到时返回 null、空集合或该 API 的默认值。
func get_string(key: String, default_value: String = "") -> String:
	if payload.has(key):
		return str(payload[key])
	return default_value


## 读取当前对象中的 `float`；未找到时返回 null、空集合或该 API 的默认值。
func get_float(key: String, default_value: float = 0.0) -> float:
	if payload.has(key):
		return float(payload[key])
	return default_value
