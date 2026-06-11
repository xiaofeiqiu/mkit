class_name GameCommand
extends RefCounted
## 说明：`GameCommand` 是 命令路由 的命令对象，负责承载输入、AI 或脚本发出的意图。
## 上游：通常由输入、AI、脚本或 CommandService 创建或调用。
## 下游：会连接CommandReceiver、StateMachine 或目标实体，不直接依赖具体游戏内容。
## 使用：当项目调用方只想表达意图，并交给 pipeline 决定如何处理时使用它。
## 示例：`var instance := GameCommand.new()`

## 运行时状态：`command_id` 表示稳定 id，由 `GameCommand` 的公开 API 读取或维护。
var command_id: String = ""
## 运行时状态：`command_type` 表示 `GameCommand` 的字段值，由 `GameCommand` 的公开 API 读取或维护。
var command_type: String = ""
## 运行时状态：`source_id` 表示稳定 id，由 `GameCommand` 的公开 API 读取或维护。
var source_id: String = ""
## 运行时状态：`target_id` 表示稳定 id，由 `GameCommand` 的公开 API 读取或维护。
var target_id: String = ""
## 运行时状态：`timestamp` 表示 `GameCommand` 的字段值，由 `GameCommand` 的公开 API 读取或维护。
var timestamp: float = 0.0
## 运行时状态：`payload` 表示事件或存档载荷，由 `GameCommand` 的公开 API 读取或维护。
var payload: Dictionary = {}
## 运行时状态：`consumed` 表示 `GameCommand` 的字段值，由 `GameCommand` 的公开 API 读取或维护。
var consumed: bool = false


## 创建并返回新的运行时对象，并保持 `GameCommand` 的领域契约一致。
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


## 执行 `mark_consumed` 对应的公开操作，并保持 `GameCommand` 的领域契约一致。
func mark_consumed() -> void:
	consumed = true


## 返回 `vector2` 对应的数据或对象，并保持 `GameCommand` 的领域契约一致。
func get_vector2(key: String, default_value: Vector2 = Vector2.ZERO) -> Vector2:
	if payload.has(key):
		return payload[key]
	return default_value


## 返回 `string` 对应的数据或对象，并保持 `GameCommand` 的领域契约一致。
func get_string(key: String, default_value: String = "") -> String:
	if payload.has(key):
		return str(payload[key])
	return default_value


## 返回 `float` 对应的数据或对象，并保持 `GameCommand` 的领域契约一致。
func get_float(key: String, default_value: float = 0.0) -> float:
	if payload.has(key):
		return float(payload[key])
	return default_value
