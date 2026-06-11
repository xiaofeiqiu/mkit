class_name ContentValidationResult
extends RefCounted
## 说明：`ContentValidationResult` 是 内容注册 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在内容注册中复用这段契约或状态时使用它。
## 示例：`var instance := ContentValidationResult.new()`

## 运行时状态：`success` 表示 `ContentValidationResult` 的字段值，由 `ContentValidationResult` 的公开 API 读取或维护。
var success: bool = true
## 运行时状态：`errors` 表示 `ContentValidationResult` 的字段值，由 `ContentValidationResult` 的公开 API 读取或维护。
var errors: Array[String] = []
## 运行时状态：`warnings` 表示 `ContentValidationResult` 的字段值，由 `ContentValidationResult` 的公开 API 读取或维护。
var warnings: Array[String] = []


## 向当前集合或状态中增加数据，并保持 `ContentValidationResult` 的领域契约一致。
func add_error(message: String) -> void:
	success = false
	errors.append(message)


## 向当前集合或状态中增加数据，并保持 `ContentValidationResult` 的领域契约一致。
func add_warning(message: String) -> void:
	warnings.append(message)
